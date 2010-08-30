describe "The Reconciliation API," do
  
  context "when performing multiple queries" do
  
    before :all do
      test_store = "ldodds-pho-reconcile"
      query = Hash.new
      query["q1"] = { "query" => "Bloggs" }
      query["q2"] = { "query" => "Whale" }        
      @response = server_get "/#{test_store}/reconcile?queries=#{CGI::escape(query.to_json)}"
    end
 
    it_should_behave_like "All Successful Responses"
    it_should_behave_like "All JSON Requests"
    it_should_behave_like "All Multi Query Mode Requests"
    
  end
  
  
end