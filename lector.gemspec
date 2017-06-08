# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "regis-lector"
  spec.version       = "0.9.0"
  spec.authors       = ["Frank Matranga"]
  spec.email         = ["thefrankmatranga@gmail.com"]

  spec.summary       = %q{Simple Moodle Scraper}
  spec.description   = %q{Super simple Moodle site scraper for Frank Matranga's high school}
  spec.homepage      = "https://github.com/Apexal/lector"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
