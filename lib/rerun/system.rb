module Rerun
  module System
    def self.mac?
      RUBY_PLATFORM =~ /darwin/i
    end

    def self.windows?
       RUBY_PLATFORM =~ /(mswin|mingw32)/i
    end

    def self.linux?
       RUBY_PLATFORM =~ /linux/i
    end

    def self.rails?
      rails_sig_file = File.expand_path File.join '.', 'config/boot.rb'
      File.exists? rails_sig_file
    end
  end
end
