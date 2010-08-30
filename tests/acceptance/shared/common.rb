shared_examples_for "All Successful Responses" do
  
    it "should have correct code and a mimetype" do
     @response.code.should == 200
     @response.headers[:content_type].should_not be_nil
    end
    
end

shared_examples_for "All JSONP Requests" do
  
    it "should have correct mimetype" do
     @response.headers[:content_type].should == "application/javascript"       
    end
    
end

shared_examples_for "All JSON Requests" do
  
    it "should have correct mimetype" do
     @response.headers[:content_type].should == "application/json"       
    end
    
end

shared_examples_for "All Single Query Mode Requests" do
  
  it "should have a result array" do
    query(@response, "$.result").should_not be_nil
    query(@response, "$.result").class.should == Array
  end
  
  it "should have results that have all required elements" do
    query(@response, "$.result").each do |result|
      result["id"].should_not be_nil
      result["name"].should_not be_nil
      result["type"].should_not be_nil
      result["score"].should_not be_nil
      result["match"].should_not be_nil  
    end
  end
      
end

shared_examples_for "All Multi Query Mode Requests" do
  
  it "should have results that have all required elements" do
    parsed = JSON.parse(@response.body)
    parsed.keys.each do |key|      
      parsed[key]["result"].each do |result|
        result["id"].should_not be_nil
        result["name"].should_not be_nil
        result["type"].should_not be_nil
        result["score"].should_not be_nil
        result["match"].should_not be_nil  
      end      
    end
  end
      
end