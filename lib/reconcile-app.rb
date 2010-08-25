require 'rubygems'
require 'pho'
require 'pho-reconcile/reconcile.rb'
require 'sinatra/base'
require 'json'

class ReconcileApp < Sinatra::Base
  
  configure do |app|
    set :static, true    
    set :views, File.dirname(__FILE__) + "/../views"
    set :public, File.dirname(__FILE__) + "/../public"
    set :config, File.dirname(__FILE__) + "/../config"    
  end
  
  def read_opts(store)
    opts = Hash.new
    config = settings.config + "/" + store + ".json"
    if File.exists?( config )
      json = JSON.load( File.new( config ) )
      json.each do |k,v|
        opts[k.to_sym] = v
      end
    end
    return opts
  end
  
  get "/" do
    @stores = Array.new
    Dir.glob("#{settings.config}/*.json").each do |file|
      storename = File.basename(file).gsub(".json", "")
      @stores << storename
    end
    erb :index
  end
  
  get "/:store/reconcile" do
    @opts = read_opts(params[:store])
    if @opts != nil && @opts[:store] != nil
      @store = Pho::Store.new("http://api.talis.com/stores/#{@opts[:store]}")
    else
      @store = Pho::Store.new("http://api.talis.com/stores/#{params[:store]}")
    end
              
    if params[:query] == nil && params[:queries] == nil
      content_type "application/json"      
      return erb :service
    elsif params[:query] != nil
      query = params[:query]      
      begin   
        
        if !query.start_with?("{")
          parsed = { "query" => query }
        else
          parsed = JSON.parse(query)  
        end
        
        reconciler = PhoReconcile::Reconciler.new( @store, @opts )        
        results = reconciler.reconcile_request(parsed)
        #resp = HTTP::Message.new_response(RESPONSE)      
        #results = reconciler.parse_response( resp )  
        response = "{ \"result\": " + results.to_json()  + " }"
              
      rescue
        #TODO specification doesn't talk about structure of error responses
        status 500
        return "Unable to perform reconcilation request"
      end
    
    else
      #multiple queries
      reconciler = PhoReconcile::Reconciler.new( @store, @opts )   
      begin
        queries = JSON.parse( params[:queries] )          
        response = {}
        queries.keys.each do |key|
          response[key] = reconciler.reconcile_request( queries[key] ) 
        end
        response = response.to_json
       rescue
         status 500
         return "Unable to perform reconciliation requests"
       end
    end

    if params[:callback] != nil
      content_type "application/javascript"
      return "#{params[:callback]}(response);"
    else
      content_type "application/json"
      return response          
    end
        
  end
  
  #This is just here for when I'm testing the app on the train...
  RESPONSE = <<-EOL 
  <rdf:RDF xmlns="http://purl.org/rss/1.0/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
    xmlns:relevance="http://a9.com/-/opensearch/extensions/relevance/1.0/" 
    xmlns:os="http://a9.com/-/spec/opensearch/1.1/"
    xmlns:nuts="http://statistics.data.gov.uk/def/nuts-geography/">
  
  <channel rdf:about="http://api.talis.com/stores/govuk-statistics/items?query=Bath">
      <title>Test Feed</title>
      <link>http://api.talis.com/stores/govuk-statistics/items?query=Bath</link>
      <description>Search for Bath</description>
      <items>
        <rdf:Seq rdf:about="urn:uuid:eae4ead8­ca6a­4b12­b714­fe631d38e447">
          <rdf:li rdf:resource="http://statistics.data.gov.uk/id/nuts-lau/UKK1201"/>
          <rdf:li rdf:resource="http://statistics.data.gov.uk/id/nuts-region/UKK1"/>
          <rdf:li rdf:resource="http://statistics.data.gov.uk/id/nuts-region/UKK12"/>
        </rdf:Seq>
      </items>
    <os:startIndex>0</os:startIndex>
    <os:itemsPerPage>10</os:itemsPerPage>
    <os:totalResults>3</os:totalResults>
  </channel>
  
  <item rdf:about="http://statistics.data.gov.uk/id/nuts-lau/UKK1201">
      <title>Bath and North East Somerset</title>
      <link>http://statistics.data.gov.uk/id/nuts-lau/UKK1201</link>
    <relevance:score>0.8</relevance:score>
    <rdf:type>
      <rdf:Description rdf:about="http://statistics.data.gov.uk/def/nuts-geography/LAULevel1"/>
    </rdf:type>   
  </item>
  
  <item rdf:about="http://statistics.data.gov.uk/id/nuts-region/UKK1">
      <title>Gloucestershire, Wiltshire and Bristol/Bath area</title>
      <link>http://statistics.data.gov.uk/id/nuts-region/UKK1</link>
    <relevance:score>0.6</relevance:score>
    <rdf:type>
      <rdf:Description rdf:about="http://statistics.data.gov.uk/def/nuts-geography/NUTSLevel2"/>
    </rdf:type>
  </item>
  
  <item rdf:about="http://statistics.data.gov.uk/id/nuts-region/UKK12">
      <title>Bath and North East Somerset, North Somerset and South Gloucestershire</title>
      <link>http://statistics.data.gov.uk/id/nuts-region/UKK12</link>
    <relevance:score>0.2</relevance:score>
    <rdf:type>
      <rdf:Description rdf:about="http://statistics.data.gov.uk/def/nuts-geography/NUTSLevel3"/>
    </rdf:type>
    
  </item>
  
  
  </rdf:RDF>
  EOL
  
end