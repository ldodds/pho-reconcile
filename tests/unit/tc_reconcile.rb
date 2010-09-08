$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'rubygems'

require 'test/unit'
require 'pho'
require 'pho-reconcile'
require 'mocha'

class ReconcileTest < Test::Unit::TestCase

  REQUEST = <<-EOL
  {
    "query": "Bath"
  }
  EOL

  TYPED_REQUEST = <<-EOL
  {
    "query": "Bath",
    "type": [
        "http://statistics.data.gov.uk/def/nuts-geography/NUTSLevel2",
        "http://www.example.org/ns/Place"
    ],
    "type_strict": "any"    
  }
  EOL
        
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
  
  def test_basic_query()
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/items", {"query" => "label:Bath", "max" => "10"}).returns( HTTP::Message.new_response(RESPONSE) )
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)    
    reconciler = PhoReconcile::Reconciler.new(store)    
    resp = reconciler.reconcile("Bath")        
  end
  
  def test_basic_query_overriding_field()
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/items", {"query" => "prefLabel:Bath", "max" => "10"}).returns( HTTP::Message.new_response(RESPONSE) )
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)    
    reconciler = PhoReconcile::Reconciler.new(store, {:search_field => "prefLabel"})    
    resp = reconciler.reconcile("Bath")        
  end
    
  def test_query_with_limit()
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/items", {"query" => "label:Bath", "max" => "20"}).returns(
    HTTP::Message.new_response(RESPONSE) )
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    
    reconciler = PhoReconcile::Reconciler.new(store)
    
    resp = reconciler.reconcile("Bath", 20)
    
  end
  
  def test_query_with_type()
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/items", {"query" => "label:Bath type:\"http://statistics.data.gov.uk/def/nuts-geography/NUTSLevel2\"", "max" => "10"}).returns(
    HTTP::Message.new_response(RESPONSE) )
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    
    reconciler = PhoReconcile::Reconciler.new(store)

    types = []
    types << "http://statistics.data.gov.uk/def/nuts-geography/NUTSLevel2"    
    resp = reconciler.reconcile("Bath", 10, types)
            
  end

  def test_query_with_any_type()
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/items", {"query" => "label:Bath (type:\"http://statistics.data.gov.uk/def/nuts-geography/NUTSLevel2\" OR type:\"http://www.example.org/ns/Place\")", "max" => "10"}).returns(
    HTTP::Message.new_response(RESPONSE) )
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    
    reconciler = PhoReconcile::Reconciler.new(store)

    types = []
    types << "http://statistics.data.gov.uk/def/nuts-geography/NUTSLevel2"
    types << "http://www.example.org/ns/Place"    
    resp = reconciler.reconcile("Bath", 10, types, :any)            
  end

  def test_query_with_all_type()
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/items", {"query" => "label:Bath (type:\"http://statistics.data.gov.uk/def/nuts-geography/NUTSLevel2\" AND type:\"http://www.example.org/ns/Place\")", "max" => "10"}).returns(
    HTTP::Message.new_response(RESPONSE) )
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    
    reconciler = PhoReconcile::Reconciler.new(store)

    types = []
    types << "http://statistics.data.gov.uk/def/nuts-geography/NUTSLevel2"
    types << "http://www.example.org/ns/Place"    
    resp = reconciler.reconcile("Bath", 10, types, :all)            
  end
      
  def test_query_with_type_and_properties()
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/items", {"query" => "label:Bath type:\"http://statistics.data.gov.uk/def/nuts-geography/NUTSLevel2\"", "max" => "10"}).returns(
    HTTP::Message.new_response(RESPONSE) )
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    
    reconciler = PhoReconcile::Reconciler.new(store)

    types = []
    types << "http://statistics.data.gov.uk/def/nuts-geography/NUTSLevel2"    
    
    properties = [ {
       "pid" => "http://www.w3.org/2004/02/skos/core#notation", 
       "v" => "UKK2"
    } ]
    
    resp = reconciler.reconcile("Bath", 10, types, :any, properties)
            
  end

  def test_parse_basic_query()
    resp = HTTP::Message.new_response(RESPONSE)
    mc = mock()
    mc.stub_everything()
    reconciler = PhoReconcile::Reconciler.new( mc )
    
    results = reconciler.parse_response(resp.status, resp.content)
    assert_not_nil(results)
    assert_equal(3, results.length)
    assert_equal("http://statistics.data.gov.uk/id/nuts-lau/UKK1201", results[0].id)
    assert_equal("0.8", results[0].score)
    
  end        
  
  def test_parse_basic_query_from_json()
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/items", {"query" => "label:Bath", "max" => "10"}).returns( HTTP::Message.new_response(RESPONSE) )
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)    
    reconciler = PhoReconcile::Reconciler.new(store)    
    resp = reconciler.reconcile_request( JSON.parse( REQUEST ) )            
  end
  
  def test_parse_typed_query_from_json()
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/items", {"query" => "label:Bath (type:\"http://statistics.data.gov.uk/def/nuts-geography/NUTSLevel2\" OR type:\"http://www.example.org/ns/Place\")", "max" => "10"}).returns(
    HTTP::Message.new_response(RESPONSE) )
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)    
    reconciler = PhoReconcile::Reconciler.new(store)    

    resp = reconciler.reconcile_request( JSON.parse( TYPED_REQUEST ) )            
  end  
end