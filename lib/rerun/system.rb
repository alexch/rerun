module Rerun
  module System

    def mac?
      # puts "RUBY_PLATFORM=#{RUBY_PLATFORM}"
      RUBY_PLATFORM =~ /darwin/i
    end

    def osx_foundation?      
      mac? and begin
        if $osx_foundation.nil?
          require 'osx/foundation'
          OSX.require_framework '/System/Library/Frameworks/CoreServices.framework/Frameworks/CarbonCore.framework'
          $osx_foundation = true
        end
        $osx_foundation
      rescue LoadError
        $osx_foundation = false
      end        
    end

    def windows?
       RUBY_PLATFORM =~ /mswin/i
    end

    def linux?
       RUBY_PLATFORM =~ /linux/i
    end

    # do we have growl or not?
    def growl?
      mac? && (growlcmd != "")
    end

    def growlcmd
      `which growlnotify`.chomp
    end
    
    def app_name
      # todo: make sure this works in non-Mac and non-Unix environments
      File.expand_path(".").gsub(/^.*\//, '').capitalize
    end

    def icon
      libdir = "#{File.expand_path(File.dirname(File.dirname(__FILE__)))}/lib"
      $LOAD_PATH.unshift libdir unless $LOAD_PATH.include?(libdir)

      rails_sig_file = File.expand_path(".")+"/config/boot.rb" 
      return "#{libdir}/../icons/rails_red_sml.png" if File.exists? rails_sig_file
      return nil
    end

    def growl(title, body, background = true)
      if growl?
        icon_str = ("--image \"#{icon}\"" if icon)
        s = "#{growlcmd} -n \"#{app_name}\" -m \"#{body}\" \"#{app_name} #{title}\" #{icon_str}"
        s += " &" if background
        `#{s}`
      end
    end
    
  end
end
