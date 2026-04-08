require_relative "lib/archivetok/version"

Gem::Specification.new do |s|
  s.name        = "archivetok"
  s.version     = Archivetok::VERSION
  s.summary     = "CLI tool to download TikTok videos and photos"
  s.authors     = ["archivetok"]
  s.executables = ["archivetok"]
  s.files       = Dir["lib/**/*.rb", "bin/*"]
  s.require_paths = ["lib"]
  s.required_ruby_version = ">= 2.6"

  s.add_dependency "nokogiri"
  s.add_dependency "colorize"
end
