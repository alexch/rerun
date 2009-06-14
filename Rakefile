require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'spec/rake/spectask'

task :default => [:spec]
task :test => :spec

desc "Run all specs"
Spec::Rake::SpecTask.new('spec') do |t|
  ENV['ENV'] = "test"
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.ruby_opts = ['-rubygems'] if defined? Gem
end

$rubyforge_project = 'XXX'

$spec =
  begin
    require 'rubygems/specification'
    data = File.read('rerun.gemspec')
    spec = nil
    Thread.new { spec = eval("$SAFE = 3\n#{data}") }.join
    spec
  end

def package(ext='')
  "pkg/#{$spec.name}-#{$spec.version}" + ext
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
  sh <<-SH
    git archive \
      --prefix=#{$spec.name}-#{$spec.version}/ \
      --format=tar \
      HEAD | gzip > #{f.name}
  SH
end

desc 'Publish gem and tarball to rubyforge'
task 'release' => [package('.gem'), package('.tar.gz')] do |t|
  sh <<-end
    rubyforge add_release #{$rubyforge_project} #{$spec.name} #{$spec.version} #{package('.gem')} &&
    rubyforge add_file    #{$rubyforge_project} #{$spec.name} #{$spec.version} #{package('.tar.gz')}
  end
end
5
