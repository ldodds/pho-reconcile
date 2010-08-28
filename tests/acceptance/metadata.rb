describe "The Reconciliation API," do
  
  context "when accessing service metadata" do

    before :all do
      RECONCILE_TEST_STORE = "ldodds-pho-reconcile"
      @response = server_get "/#{RECONCILE_TEST_STORE}/reconcile"
    end

    it_should_behave_like "All Successful Responses"
    it_should_behave_like "All JSON Requests"
    
    it "should have the basic required fields" do
      query(@response, "$.name").should_not be_nil
      query(@response, "$.identifierSpace").should_not be_nil  
      query(@response, "$.schemaSpace").should_not be_nil
    end
    
    it "should specify the resource URI as the viewer" do
      view = query(@response, "$.view")
      view.should_not be_nil
      view["url"].should_not be_nil
      view["url"].should == "{{id}}"        
    end
    
  end
   
end