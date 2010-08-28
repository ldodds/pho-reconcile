require 'rake'

require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rake/clean'
require 'pho'

NAME = "pho-reconcile"
VER = "0.0.2"
PKG_FILES = %w( README.rdoc Rakefile ) + 
  Dir.glob("{bin,lib,public,views}/**/*")

RECONCILE_TEST_STORE="http://api.talis.com/stores/ldodds-pho-reconcile"

CLEAN.include ['*.gem', 'pkg']  
SPEC =
  Gem::Specification.new do |s|
    s.name = NAME
    s.version = VER
    s.platform = Gem::Platform::RUBY
    s.required_ruby_version = ">= 1.8.5"    
    s.has_rdoc = true
    s.extra_rdoc_files = ["README.rdoc"]
    s.summary = "Reconciliation API for Talis Platform Stores"
    s.description = "Implementation of the Gridworks Reconciliation API"
    s.author = "Leigh Dodds"
    s.email = 'leigh.dodds@talis.com'
    s.homepage = 'http://github.com/ldodds/gridworks-reconcile'
    s.files = PKG_FILES
    s.require_path = "lib" 
    s.bindir = "bin"
    
    #For core implementation
    s.executables = ["pho-reconciler"]
    s.add_dependency("pho", ">= 0.7.3")
    s.add_dependency("sinatra", ">= 1.0")

    #For acceptance tests
    s.add_dependency("siren")
    s.add_dependency("rest-client")
    s.add_dependency("rspec")
    s.add_dependency("json")

  end
      
Rake::GemPackageTask.new(SPEC) do |pkg|
    pkg.need_tar = true
end

desc "Install from a locally built copy of the gem"
task :install do
  sh %{rake package}
  sh %{sudo gem install pkg/#{NAME}-#{VER}}
end

desc "Uninstall the gem"
task :uninstall => [:clean] do
  sh %{sudo gem uninstall #{NAME}}
end

desc "Prepare store configuration for testing"
task :prepare_store do
  storename = ENV[RECONCILE_TEST_STORE] || RECONCILE_TEST_STORE
  puts "Preparing Field-Predicate Map for #{storename}"
  store = Pho::Store.new(storename, ENV["TALIS_USER"], ENV["TALIS_PASS"])
  fpmap = Pho::FieldPredicateMap.read_from_store(store)
  fpmap.datatype_properties.each do |prop|
    fpmap.remove_by_name( prop.name )
  end
  fpmap << Pho::FieldPredicateMap.create_mapping(store, "http://www.w3.org/2000/01/rdf-schema#label", "label")
  fpmap << Pho::FieldPredicateMap.create_mapping(store, "http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "type")
  fpmap << Pho::FieldPredicateMap.create_mapping(store, "http://xmlns.com/foaf/0.1/name", "name")
  fpmap.upload(store)
end
  
desc "Load test data into the acceptance test store. Set TALIS_USER and TALIS_PASS env variables"
task :load_test_data do
  storename = ENV[RECONCILE_TEST_STORE] || RECONCILE_TEST_STORE  
  sh %{talis_store store -s #{storename} -f tests/acceptance/test-data.ttl}  
end

desc "Prepare acceptance test store"
task :prepare_acceptance => [:prepare_store, :load_test_data]
  
desc "Run acceptance test suite"
task :acceptance do
  sh %{spec tests/acceptance/suite.spec}  
end

Rake::TestTask.new do |test|
  test.test_files = FileList['tests/unit/tc_*.rb']
end