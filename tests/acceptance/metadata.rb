describe "The Reconciliation API," do
  
  context "when accessing service metadata" do

    before :all do
      @response = server_get "/govuk-statistics/reconcile"
    end

    it_should_behave_like "All Successful Responses"
    it_should_behave_like "All JSON Requests"
        
  end
   
end