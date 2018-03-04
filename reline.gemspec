
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'reline/version'

Gem::Specification.new do |spec|
  spec.name          = 'reline'
  spec.version       = Reline::VERSION
  spec.authors       = ['aycabta']
  spec.email         = ['aycabta@gmail.com']

  spec.summary       = %q{Alternative GNU Readline or Editline implementation by pure Ruby.}
  spec.description   = %q{Alternative GNU Readline or Editline implementation by pure Ruby.}
  spec.homepage      = 'https://github.com/aycabta/reline'
  spec.license       = 'Ruby License'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
end
