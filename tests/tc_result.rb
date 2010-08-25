$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'rubygems'

require 'test/unit'
require 'pho'
require 'pho-reconcile'
require 'mocha'

class ResultTest < Test::Unit::TestCase
  
  def test_match_string_property()
    filter = { "pid" => "http://xmlns.com/foaf/0.1/name", "v" => "Joe Bloggs" }    
    result = PhoReconcile::Result.new("test", "Test Result", "1.0", true, [], {} )      
    assert_equal( false, result.matches?( [ filter ]) )
      
    result = PhoReconcile::Result.new("test", "Test Result", "1.0", true, [], 
      { "http://xmlns.com/foaf/0.1/name" => "Bob" } )      
    assert_equal( false, result.matches?( [ filter ]) )            
      
    result = PhoReconcile::Result.new("test", "Test Result", "1.0", true, [], 
      { "http://xmlns.com/foaf/0.1/name" => "Joe Bloggs" } )      
    assert_equal( true, result.matches?( [ filter ]) )            
      
  end
  
  def test_match_integer_property()
    filter = { "pid" => "http://example.org/age", "v" => 22 }    
    result = PhoReconcile::Result.new("test", "Test Result", "1.0", true, [], {} )      
    assert_equal( false, result.matches?( [ filter ]) )
      
    result = PhoReconcile::Result.new("test", "Test Result", "1.0", true, [], 
      { "http://example.org/age" => 42 } )      
    assert_equal( false, result.matches?( [ filter ]) )            
      
    result = PhoReconcile::Result.new("test", "Test Result", "1.0", true, [], 
      { "http://example.org/age" => "22" } )      
    assert_equal( true, result.matches?( [ filter ]) )            
      
  end
  
  def test_match_array_of_string_property()
    filter = { "pid" => "http://example.org/category", "v" => ["maths", "history"] }    
    result = PhoReconcile::Result.new("test", "Test Result", "1.0", true, [], {} )      
    assert_equal( false, result.matches?( [ filter ]) )
      
    result = PhoReconcile::Result.new("test", "Test Result", "1.0", true, [], 
      { "http://example.org/category" => "maths" } )      
    assert_equal( false, result.matches?( [ filter ]) )            

    result = PhoReconcile::Result.new("test", "Test Result", "1.0", true, [], 
      { "http://example.org/category" => "history" } )      
    assert_equal( false, result.matches?( [ filter ]) )     
                        
  end    
end