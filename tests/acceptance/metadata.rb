describe "The Reconciliation API," do
  
  context "when accessing service metadata" do

    before :all do
      RECONCILE_TEST_STORE = "ldodds-pho-reconcile"
      @response = server_get "/#{RECONCILE_TEST_STORE}/reconcile"
    end

    it_should_behave_like "All Successful Responses"
    it_should_behave_like "All JSON Requests"
        
  end
   
end