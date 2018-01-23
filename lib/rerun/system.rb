module Rerun
  module System

    def mac?
      RUBY_PLATFORM =~ /darwin/i
    end

    def windows?
       RUBY_PLATFORM =~ /(mswin|mingw32)/i
    end

    def linux?
       RUBY_PLATFORM =~ /linux/i
    end

    def rails?
      rails_sig_file = File.expand_path(".")+"/config/boot.rb"
      File.exists? rails_sig_file
    end

  end
end
