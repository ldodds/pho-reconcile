describe "The Reconciliation API," do
  
  context "when accessing service metadata" do

    before :all do
      test_store = "ldodds-pho-reconcile"
      @response = server_get "/#{test_store}/reconcile"
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

  context "when accessing service metadata as JSONP" do

    before :all do
      test_store = "ldodds-pho-reconcile"
      @function = "function"
      @response = server_get "/#{test_store}/reconcile?callback=function"
      @regex = Regexp.new( "(.+)\\((.+)\\)", Regexp::MULTILINE )
    end

    it_should_behave_like "All Successful Responses"
    it_should_behave_like "All JSONP Requests"
       
    it "should use the named callback" do
      @regex.match(@response.body).should_not be_nil
      @regex.match(@response.body)[1].should == @function
    end
    
    it "should contain JSON data that includes the required fields" do      
      data = @regex.match( @response.body )[2]
      json = JSON.parse(data)
      Siren.query("$.name", json).should_not be_nil
      Siren.query("$.identifierSpace", json).should_not be_nil  
      Siren.query("$.schemaSpace", json).should_not be_nil      
    end
  end     
end