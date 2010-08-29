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
