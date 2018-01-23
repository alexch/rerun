source 'https://rubygems.org'

gemspec

# :ruby = Unix Rubies (OSX, Linux)
# but rb-fsevent is OSX-only, so how to distinguish between OSX and Linux?
platform :ruby do
  gem 'rb-fsevent', '>= 0.9.3'
end

group :development do
  gem "rake", '>= 0.10'
end

group :test do
  gem 'rspec', ">=3.0"
  gem 'wrong', ">=0.6.2"
end

gem 'wdm', '>= 0.1.0' if Gem.win_platform?
