module Rerun
  module System

    def mac?
      RUBY_PLATFORM =~ /darwin/i
    end

    def windows?
       RUBY_PLATFORM =~ /mswin/i
    end

    def linux?
       RUBY_PLATFORM =~ /linux/i
    end

    # do we have growl or not?
    def growl_available?
      mac? && (growlcmd != "")
    end

    def growlcmd
      growlnotify = `which growlnotify`.chomp
      # todo: check version of growlnotify and warn if it's too old
      growlnotify
    end

    def icon
      here = File.expand_path(File.dirname(__FILE__))
      icondir = File.expand_path("#{here}/../../icons")
      rails_sig_file = File.expand_path(".")+"/config/boot.rb"
      "#{icondir}/rails_red_sml.png" if File.exists? rails_sig_file
    end

    def growl(title, body, background = true)
      if growl_available?
        icon_str = ("--image \"#{icon}\"" if icon)
        s = "#{growlcmd} -n \"#{app_name}\" -m \"#{body}\" \"#{app_name} #{title}\" #{icon_str}"
        s += " &" if background
        `#{s}`
      end
    end

  end
end
