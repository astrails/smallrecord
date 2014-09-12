# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "small_record/version"

Gem::Specification.new do |s|
  s.name        = 'SmallRecord'
  s.version     = SmallRecord::VERSION
  s.platform    = Gem::Platform::RUBY
  s.date        = File.new("lib/small_record/version.rb").ctime
  s.authors     = ["Vitaly Kushner"]
  s.email       = ["vitalyk@gmail.com"]
  s.homepage    = "https://github.com/astrails/smallrecord"
  s.summary     = %q{Simple Object persistency library for Cassandra (ActiveRecord replacement for Rails)}
  s.description = %q{Simple Object persistency library for Cassandra (ActiveRecord replacement for Rails)}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {spec}/*`.split("\n")
  s.require_paths = ['lib']

  s.add_dependency 'activemodel'
  s.add_dependency 'activesupport'
end
