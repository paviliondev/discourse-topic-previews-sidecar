# -*- encoding: utf-8 -*-
# stub: prizm 0.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "prizm".freeze
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Quan Nguyen".freeze]
  s.date = "2015-05-24"
  s.description = "Prizm uses rmagick to extract colors from images".freeze
  s.email = ["mquannie@gmail.com <mailto:mquannie@gmail.com>".freeze]
  s.homepage = "".freeze
  s.rubygems_version = "3.1.4".freeze
  s.summary = "Prizm is a ruby gem that extracts colors from an input image".freeze

  s.installed_by_version = "3.1.4" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rmagick>.freeze, [">= 0"])
  else
    s.add_dependency(%q<rmagick>.freeze, [">= 0"])
  end
end
