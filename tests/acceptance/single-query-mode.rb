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
  
end