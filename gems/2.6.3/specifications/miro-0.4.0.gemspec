# -*- encoding: utf-8 -*-
# stub: miro 0.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "miro".freeze
  s.version = "0.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jon Buda".freeze]
  s.date = "2016-03-24"
  s.description = "Extract the dominant colors from an image.".freeze
  s.email = ["jon.buda@gmail.com".freeze]
  s.homepage = "https://github.com/jonbuda/miro".freeze
  s.licenses = ["MIT".freeze]
  s.requirements = ["ImageMagick".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Extract the dominant colors from an image.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<cocaine>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<color>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<chunky_png>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<oily_png>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_development_dependency(%q<fakeweb>.freeze, [">= 0"])
    else
      s.add_dependency(%q<cocaine>.freeze, [">= 0"])
      s.add_dependency(%q<color>.freeze, [">= 0"])
      s.add_dependency(%q<chunky_png>.freeze, [">= 0"])
      s.add_dependency(%q<oily_png>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_dependency(%q<fakeweb>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<cocaine>.freeze, [">= 0"])
    s.add_dependency(%q<color>.freeze, [">= 0"])
    s.add_dependency(%q<chunky_png>.freeze, [">= 0"])
    s.add_dependency(%q<oily_png>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<fakeweb>.freeze, [">= 0"])
  end
end
