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
        "type" => types,
        "properties" => properties
      }.to_json(*a)
    end
  end
  
  #Performs reconciliation tasks against the search index of a Talis Platfom store
  class Reconciler
    
    attr_reader :store, :opts
        
    def initialize(store, opts={})
      @store = store
      @opts = opts
    end
    
    #perform reconcilation as described in the provided json
    def reconcile_request(obj)
      query = obj["query"]
      limit = 10
      types = Array.new
      type_strict = :any

      if obj["limit"] != nil
        limit = obj["limit"].to_i
      end      
      
      properties = Hash.new
      
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
        if (type_strict != :all || type_strict != :any)
          type_strict = :any
        end
        #TODO implement :should = as with any, but gets a boost on score if matches
      end
      
      if obj["properties"] != nil
        properties = properties
      end
      
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
    def reconcile(query, limit=10, types=[], type_strict=:any, properties={})
      #TODO make this configurable so we can search several different fields?      
      search = "#{search_field()}:#{query}"
      opts = {
       "limit" => limit.to_s
      }
      
      if types.length > 0
        if type_strict == :any
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
      
      puts search
      
      #Note: this assumes labels in fpmap. Could also pass as URIs
      #FIXME: doesn't support nested ids -- handle as SPARQL?
      if !properties.empty?
        search = search + " " + properties.to_a.map { |entry| "#{entry[0]}:#{entry[1]}" }.join(" ")        
      end
        
      resp = @store.search(search, opts)
            
      return parse_response(resp)
    end
    
    #parse a platform search response into an array of Response objects
    def parse_response(resp)
      if resp.status != 200
        raise "Unable to read search response: #{resp.status} #{resp.content}"
      end
      doc = REXML::Document.new(resp.content)
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
          
        label = REXML::XPath.first(el, "rss:title", PhoReconcile::NAMESPACES ).text
        score = REXML::XPath.first(el, "relevance:score", PhoReconcile::NAMESPACES ).text
        match = match?(score)
        
        #Add types
        types = Array.new
        properties = Hash.new
                
        el.elements.each do |child|
          if child.prefix != NAMESPACES["rss"]
            if child.prefix != nil && child.prefix != ""
              full_name = "#{child.namespaces[child.prefix]}#{child.name}"
              if full_name == "http://www.w3.org/1999/02/22-rdf-syntax-ns#type"
                   desc = REXML::XPath.first(child, "rdf:Description", PhoReconcile::NAMESPACES)
                   types << desc.attributes["rdf:about"]
              #this allows override of how name is generated. Default is from rss:title
              elsif @opts[:label_property] != nil && full_name == @opts[:label_property]
                  label = child.text
              else
                  #TODO other properties                       
              end
            end
          end
        end
        
        results << Result.new( id, label, score, match, types, properties )
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