module PhoReconcile
  
  NAMESPACES = {
    "rdf" => "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
    "rss" => "http://purl.org/rss/1.0/",
    "os" => "http://a9.com/-/spec/opensearch/1.1/",
    "relevance" => "http://a9.com/-/opensearch/extensions/relevance/1.0/"
  }
  
  #A reconciliation result
  class Result
    attr_reader :id, :label, :score, :types, :properties, :match
    
    def initialize(id, label, score, match, types=[], properties={})
      @id = id
      @label = label
      @score = score
      @match = match
      @types = types
      @properties = properties
    end
        
    def to_json(*a)
      return {
        "id" => @id,
        "name" => @label,
        "score" => @score,
        "match" => @match,
        "type" => types
      }.to_json(*a)
    end

    #Implements filtering based on properties specified in the reconciliation
    #request. The filters parameter is an array of hashes of the form:
    #
    #  {
    #   "p" : string, property name, e.g., "country", or
    #   "pid" : string, property ID, e.g., "/people/person/nationality" in the Freebase ID space
    #   "v" : a single, or an array of, string or number or object literal, e.g., "Japan"
    #  }
    #
    # Only a pid values are supported in this implementation     
    def matches?(filters)
      
      return true if filters.length == 0
        
      filters.each do |filter|        
        pid = filter["pid"]
        if @properties[ pid ] != nil        
          v = filter["v"]
          if v.class == "Array"
            v.each do |value|
              #TODO for multiple values do they all match?
              value = v["id"] if v.class == "Object"
              value = v.to_s if v.class != "Object"
              return false if !match_property?(pid, value)              
            end
          else
            value = v["id"] if v.class == "Object"
            value = v.to_s if v.class != "Object"
            return false if !match_property?(pid, value)
          end
        else
          return false
        end
        
      end
      
      return true
            
    end
    
    def match_property?(pid, value)
      return true if @properties[pid].to_s == value
      return false
    end
    
  end
  
  #Performs reconciliation tasks against the search index of a Talis Platfom store
  class Reconciler
    
    attr_reader :store, :opts
        
    def initialize(store, opts={})
      @store = store
      @opts = opts
    end
    
    #Decompose the request into individual variables
    #
    #Used to provide some separation between format of Gridworks query and 
    #the methods that do the work. 
    #
    #returns: query, limit, types, type_strict, properties
    def decompose(obj)
      query = obj["query"]
      limit = 10
      types = Array.new
      type_strict = :any

      if obj["limit"] != nil
        limit = obj["limit"].to_i
      end
      
      if obj["type"] != nil
        if obj["type"].class == "String"
          types << obj["type"]
        else
          obj["type"].each do |type|        
            types << type
          end
        end
      end
      
      if obj["type_strict"] != nil
        type_strict = obj["type_strict"].to_sym
        #treat unrecognised values as :any  
        if (type_strict != :all || type_strict != :any || type_strict != :should)
          type_strict = :any
        end
      end
      
      properties = Array.new
      if obj["properties"] != nil
        properties = properties
      end

      return query, limit, types, type_strict, properties       
    end
        
    #Perform a reconcilation request as described in the provided json object
    def reconcile_request(obj)      
      query, limit, types, type_strict, properties = decompose(obj)
      return reconcile(query, limit, types, type_strict, properties)
    end
    
    def search_field()
      return @opts[:search_field] || "label"
    end
    
    def type_field()
      return @opts[:type_field] || "type"
    end
    
    #perform reconciliation
    #
    #  type_strict:: :any, :all, ...
    def reconcile(query, limit=10, types=[], type_strict=:any, properties=[])
      search, opts = make_search(query, limit, types, type_strict, properties)
      resp = @store.search(search, opts)

      return parse_response(resp.status, resp.content, properties)
    end
    
    def make_search(query, limit, types=[], type_strict=:ant, properties=[])
      #TODO make this configurable so we can search several different fields?
      if search_field() != "*"      
        search = "#{search_field()}:#{query}"
      else        
        search = query
      end
      
      opts = {
       "max" => limit.to_s
      }
      
      if types.length > 0
        #treat :should like :any
        if type_strict == :any || type_strict == :should           
           if types.length == 1
             search = search + " #{type_field()}:\"#{types[0]}\""
           else
             search = search + " (" + types.map { |type| "#{type_field()}:\"#{type}\""}.join(" OR ") + ")"
           end
         end
         if type_strict == :all
           if types.length == 1
             search = search + " #{type_field()}:<#{types[0]}>"
           else
             search = search + " (" + types.map { |type| "#{type_field()}:\"#{type}\""}.join(" AND ") + ")"
           end
         end
      end
      return search, opts
            
    end
      
    #parse a platform search response into an array of Response objects
    def parse_response(status, content, filters=[])
      if status != 200
        raise "Unable to read search response: #{status} #{content}"
      end
      doc = REXML::Document.new(content)
      results = Array.new
      
      #TODO
      #
      # Score boosting:
      #  for :should we need to boost score if type matches
      #
      # Property filtering:
      #  if properties are specified, we need to filter the results
      #  based on the property.
      #  URI based properties need to be filtered locally
      #  Literal properties *could be filtered in search*
      #
      #  Local filtering may effect number of results. Optionally re-search?
      #      
      REXML::XPath.each(doc.root, "//rss:item", PhoReconcile::NAMESPACES) do |el|
        id = el.attributes["rdf:about"]

        #default label          
        label = REXML::XPath.first(el, "rss:title", PhoReconcile::NAMESPACES ).text
        score = REXML::XPath.first(el, "relevance:score", PhoReconcile::NAMESPACES ).text
        match = match?(score)
        
        #Add types
        types = Array.new
        properties = Hash.new
                
        #TODO handle multi-valued properties
        el.elements.each do |child|
          if child.prefix != NAMESPACES["rss"]
            if child.prefix != nil && child.prefix != ""
              #Work around REXML issues with older version of Ruby
              if RUBY_VERSION < "1.8.7"
                full_name = "#{child.namespace(child.prefix)}#{child.name}"
              else
                full_name = "#{child.namespaces[child.prefix]}#{child.name}"
              end
              if full_name == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"
                   desc = REXML::XPath.first(child, "rdf:Description", PhoReconcile::NAMESPACES)
                   types << desc.attributes["rdf:about"]
              else
                  #resource?
                  desc = REXML::XPath.first(child, "rdf:Description", PhoReconcile::NAMESPACES)
                  if desc != nil
                    properties[full_name] = desc.attributes["rdf:about"]
                  else
                    properties[full_name] = child.text
                  end       
              end
            end
          end
        end

        if @opts["label_property"] != nil && properties[ @opts[:label_property] ] != nil
          label = properties[ @opts[:label_property] ]
        else
          label = properties["http://www.w3.org/2000/01/rdf-schema#label"] || label          
          label = properties["http://www.w3.org/2004/02/skos/core#prefLabel"] || label          
          label = properties["http://xmlns.com/foaf/0.1/name"] || label
          label = properties["http://purl.org/dc/terms/title"] || label
        end
                
        result = Result.new( id, label, score, match, types, properties )
        
        if result.matches?(filters)
          results << result 
        end
        
      end

      return results
    end
        
    #Does this score count as a match?
    def match?(score)
      if @opts[:match_score] != nil
        match_score = @opts[:match_score].to_f
      else
        match_score = 1.0
      end
      if score.to_f >= match_score
        return true
      end   
      return false
    end
  end
  
end