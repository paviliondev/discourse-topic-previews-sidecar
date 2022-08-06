# -*- encoding: utf-8 -*-
# stub: colorscore 0.0.5 ruby lib

Gem::Specification.new do |s|
  s.name = "colorscore".freeze
  s.version = "0.0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Milo Winningham".freeze]
  s.date = "2016-01-06"
  s.description = "Finds the dominant colors in an image and scores them against a user-defined palette, using the CIE2000 Delta E formula.".freeze
  s.email = ["milo@winningham.net".freeze]
  s.rubygems_version = "3.3.15".freeze
  s.summary = "Finds the dominant colors in an image.".freeze

  s.installed_by_version = "3.3.15" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<color>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<test-unit>.freeze, [">= 0"])
  else
    s.add_dependency(%q<color>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<test-unit>.freeze, [">= 0"])
  end
end
