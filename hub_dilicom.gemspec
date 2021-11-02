$:.push File.expand_path("../lib", __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "hub_dilicom"
  s.version     = "0.5.0"
  s.authors     = ["Julien Boulnois"]
  s.email       = ["jboulnois@immateriel.fr"]
  s.summary     = "HUB Dilicom ruby library"
  s.description = "HUB Dilicom ruby library"

  s.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  s.test_files = Dir["test/**/*"]

  s.add_dependency "savon", '~> 2.0'

  s.add_development_dependency "bundler"
  s.add_development_dependency "rake"
  s.add_development_dependency "shoulda"
  s.add_development_dependency "rdoc"
  s.add_development_dependency "simplecov"

  s.required_ruby_version = '>= 2.1'
end
