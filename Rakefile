require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rspec/core/rake_task'

task :default => [:spec]
task :test => :spec

desc "Run all specs"
RSpec::Core::RakeTask.new('spec') do |t|
  ENV['ENV'] = "test"
  t.pattern = 'spec/**/*_spec.rb'
  t.rspec_opts = ['--color']
end

$rubyforge_project = 'pivotalrb'

$spec =
  begin
    require 'rubygems/specification'
    data = File.read('rerun.gemspec')
    spec = nil
    #Thread.new { spec = eval("$SAFE = 3\n#{data}") }.join
    spec = eval data
    spec
  end

def package(ext='')
  "pkg/#{$spec.name}-#{$spec.version}" + ext
end

desc 'Exit if git is dirty'
task :check_git do
  state = `git status 2> /dev/null | tail -n1`
  clean = (state =~ /working (directory|tree) clean/)
  unless clean
    warn "can't do that on an unclean git dir"
    exit 1
  end
end

desc 'Build packages'
task :package => %w[.gem .tar.gz].map { |e| package(e) }

desc 'Build and install as local gem'
task :install => package('.gem') do
  sh "gem install #{package('.gem')}"
end

directory 'pkg/'
CLOBBER.include('pkg')

file package('.gem') => %W[pkg/ #{$spec.name}.gemspec] + $spec.files do |f|
  sh "gem build #{$spec.name}.gemspec"
  mv File.basename(f.name), f.name
end

file package('.tar.gz') => %w[pkg/] + $spec.files do |f|
  cmd = <<-SH
    git archive \
      --prefix=#{$spec.name}-#{$spec.version}/ \
      --format=tar \
      HEAD | gzip > #{f.name}
  SH
  sh cmd.gsub(/ +/, ' ')
end

desc 'Publish gem and tarball to rubyforge'
task 'release' => [:check_git, package('.gem'), package('.tar.gz')] do |t|
  puts "Releasing #{$spec.version}"
  sh "gem push #{package('.gem')}"
  puts "Tagging and pushing"
  sh "git tag v#{$spec.version}"
  sh "git push && git push --tags"
end

desc 'download github issues and pull requests'
task 'github' do
  %w(issues pulls).each do |type|
    sh "curl -o #{type}.json https://api.github.com/repos/alexch/rerun/#{type}"
  end
end
