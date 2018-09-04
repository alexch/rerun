$spec = Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=

  s.name = 'rerun'
  s.version = '0.13.1'

  s.description = "Restarts your app when a file changes. A no-frills, command-line alternative to Guard, Shotgun, Autotest, etc."
  s.summary     = "Launches an app, and restarts it whenever the filesystem changes. A no-frills, command-line alternative to Guard, Shotgun, Autotest, etc."

  s.authors = ["Alex Chaffee"]
  s.email = "alex@stinky.com"

  s.files = %w[
    README.md
    LICENSE
    Rakefile
    rerun.gemspec
    bin/rerun
    icons/rails_grn_sml.png
    icons/rails_red_sml.png] +
      Dir['lib/**/*.rb']
  s.executables = ['rerun']
  s.test_files = s.files.select {|path| path =~ /^spec\/.*_spec.rb/}

  s.extra_rdoc_files = %w[README.md]

  s.add_runtime_dependency 'listen', '~> 3.0'

  s.homepage = "http://github.com/alexch/rerun/"
  s.require_paths = %w[lib]

  s.license = 'MIT'
end
