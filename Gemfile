source :rubygems

gemspec

# :ruby = Unix Rubies (OSX, Linux)
# but rb-fsevent is OSX-only, so how to distinguish between OSX and Linux?
platform :ruby do
  gem 'rb-fsevent', '>= 0.9.1'
end

group :development do
  gem "rake"
end

group :test do
  gem 'rspec'
  gem 'wrong', ">=0.6.2"
end
