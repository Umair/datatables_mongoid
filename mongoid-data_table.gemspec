$:.push File.expand_path("../lib", __FILE__)
require "mongoid/data_table/version"

Gem::Specification.new do |s|
  s.name        = "datatables_mongoid"
  s.version     = Mongoid::DataTable::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Umair Ejaz"]
  s.email       = ["umairejaz.ch@gmail.com"]
  s.homepage    = "https://github.com/Umair/datatables_mongoid"
  s.summary     = %q{Simple data preparation from Mongoid to the jQuery DataTables plugin}
  s.description = %q{Simple data preparation from Mongoid to the jQuery DataTables plugin}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "rails", ">= 3.0.0"
  s.add_dependency "kaminari", "~> 0.13.0"

  s.add_development_dependency "rake"
  s.add_development_dependency "bson_ext", "~>1.3"
  s.add_development_dependency "mongoid", "~>2.1"
  s.add_development_dependency "mocha", "~>0.10.0"
  s.add_development_dependency "rspec", "~>2.8"
  s.add_development_dependency "guard", "~>0.10"
  s.add_development_dependency "guard-rspec"
  s.add_development_dependency "guard-spork"
  s.add_development_dependency "spork", "~>0.9.0.rc"
  s.add_development_dependency "rb-fsevent"
  s.add_development_dependency "growl"
  s.add_development_dependency "libnotify"

end
