require 'rake'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'rake/testtask'
require 'rake/clean'

NAME = "pho-reconcile"
VER = "0.0.2"
PKG_FILES = %w( README.rdoc Rakefile ) + 
  Dir.glob("{bin,lib,public,views}/**/*")

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

task :acceptance do
  sh %{spec tests/acceptance/suite.spec}  
end

Rake::TestTask.new do |test|
  test.test_files = FileList['tests/unit/tc_*.rb']
end