require 'rubygems'
require 'cgi'
require 'spec'
require 'rest_client'
require 'siren'
require 'json'

def server()
  return ENV["RECONCILE_BASE"] || "localhost:9090"
end

def server_get(path, opts = {})
  #using the block form here so that we don't throw exceptions for 
  #HTTP error codes. Makes the testing clearer
  RestClient.get "#{server()}#{path}", opts do |response, request, result|
    return response
  end
end

def server_post(path, opts = {})
  #using the block form here so that we don't throw exceptions for 
  #HTTP error codes. Makes the testing clearer
  RestClient.post "#{server()}#{path}", opts do |response, request, result|
    return response
  end  
end

#parse HTTP response and run a Siren query over it
def query(response, query)
  json = JSON.parse(response.body)
  return Siren.query(query, json)
end