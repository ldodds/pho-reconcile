describe "The Reconciliation API," do
  
 context "when performing an abbreviated query" do
 
   before :all do
     test_store = "ldodds-pho-reconcile"
     @response = server_get "/#{test_store}/reconcile?query=Bloggs"
   end

   it_should_behave_like "All Successful Responses"
   it_should_behave_like "All JSON Requests"
   it_should_behave_like "All Single Query Mode Requests"
   
 end

  context "when performing a query" do
  
    before :all do
      test_store = "ldodds-pho-reconcile"
      query = Hash.new
      query["query"] = "Bloggs"        
      @response = server_get "/#{test_store}/reconcile?query=#{CGI::escape(query.to_json)}"
    end
 
    it_should_behave_like "All Successful Responses"
    it_should_behave_like "All JSON Requests"
    it_should_behave_like "All Single Query Mode Requests"
    
  end
  
  context "when performing a limit query" do
  
    before :all do
      test_store = "ldodds-pho-reconcile"
      query = Hash.new
      query["query"] = "Joe"  
      query["limit"] = 1     
      @response = server_get "/#{test_store}/reconcile?query=#{CGI::escape(query.to_json)}"
    end
 
    it_should_behave_like "All Successful Responses"
    it_should_behave_like "All JSON Requests"
    it_should_behave_like "All Single Query Mode Requests"
 
    it "should have only the requested number of results" do
      query(@response, "$.result").length.should == 1
    end
    
  end
  
  context "when performing a type query" do
    
    before :all do
      test_store = "ldodds-pho-reconcile"
      query = Hash.new
      query["query"] = "Joe"  
      query["type"] = "http://xmlns.com/foaf/0.1/Person"     
      @response = server_get "/#{test_store}/reconcile?query=#{CGI::escape(query.to_json)}"
    end
    
    it_should_behave_like "All Successful Responses"
    it_should_behave_like "All JSON Requests"
    it_should_behave_like "All Single Query Mode Requests"
 
    it "should have results of only the requested type" do
      query(@response, "$.result").each do |result|
        result["type"][0].should == "http://xmlns.com/foaf/0.1/Person"
      end
    end
        
  end
end