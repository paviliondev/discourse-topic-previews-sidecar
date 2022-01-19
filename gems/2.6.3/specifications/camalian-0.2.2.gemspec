# -*- encoding: utf-8 -*-
# stub: camalian 0.2.2 ruby lib

Gem::Specification.new do |s|
  s.name = "camalian".freeze
  s.version = "0.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nazar Hussain".freeze]
  s.date = "2021-04-19"
  s.description = "Library used to deal with colors and images".freeze
  s.email = ["nazarhussain@gmail.com".freeze]
  s.homepage = "https://github.com/nazarhussain/camalian".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Library used to deal with colors and images. You can extract colors from images.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<chunky_png>.freeze, ["~> 1.3", ">= 1.3.14"])
      s.add_development_dependency(%q<minitest>.freeze, ["~> 5.14", ">= 5.14.2"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 13.0", ">= 13.0.1"])
    else
      s.add_dependency(%q<chunky_png>.freeze, ["~> 1.3", ">= 1.3.14"])
      s.add_dependency(%q<minitest>.freeze, ["~> 5.14", ">= 5.14.2"])
      s.add_dependency(%q<rake>.freeze, ["~> 13.0", ">= 13.0.1"])
    end
  else
    s.add_dependency(%q<chunky_png>.freeze, ["~> 1.3", ">= 1.3.14"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.14", ">= 5.14.2"])
    s.add_dependency(%q<rake>.freeze, ["~> 13.0", ">= 13.0.1"])
  end
end
