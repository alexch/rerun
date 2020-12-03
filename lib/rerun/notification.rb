# todo: unit tests
require 'open3'

module Rerun
  class Notification
    attr_reader :title, :body, :options

    def initialize(title, body, options = Options::DEFAULTS.dup)
      @title = title
      @body = body
      @options = options
    end

    def command
      # todo: strategy or subclass
      if (options[:notify] == true or options[:notify] == 'growl') and EXISTING_NOTIFIERS.include?('growlnotify')
          # todo: check version of growlnotify and warn if it's too old
          cmd = ['growlnotify', '-n', app_name, '-m', body, "#{app_name} #{title}"]
          cmd += ['--image', icon] if icon
          return cmd
      end

      if (options[:notify] == true or options[:notify] == 'osx' ) and EXISTING_NOTIFIERS.include?('terminal-notifier')
        cmd = ['terminal-notifier', '-title', app_name, '-message', body, "#{app_name} #{title}"]
        cmd += ['-appIcon', icon] if icon
        return cmd
      end

      if (options[:notify] == true or options[:notify] == "notify-send") and EXISTING_NOTIFIERS.include?('notify-send')
          icon_str = "--icon #{icon}" if icon
          cmd = ['notify-send', '-t', '500', '--hint=int:transient:1', "#{app_name}: #{title}", body]
          cmd += ['--icon', icon] if icon
          return cmd
      end

      nil
    end

    def self.command_exist?(name)
        which = System.windows? ? 'where.exe' : 'which'
        *_, status = Open3.capture3 which, name
        status.exitstatus == 0
    end

    EXISTING_NOTIFIERS = %w[growlnotify terminal-notifier notify-send]
                              .select { |n| command_exist? n }
                              .freeze

    def send(background = true)
      return unless command
      with_clean_env do
        Open3.capture3 *command
      end
    end

    def app_name
      options[:name]
    end

    def icon
      "#{icon_dir}/rails_red_sml.png" if System.rails?
    end

    def icon_dir
      here = File.expand_path(File.dirname(__FILE__))
      File.expand_path("#{here}/../../icons")
    end

    def with_clean_env
      if defined?(Bundler)
        Bundler.with_clean_env do
          yield
        end
      else
        yield
      end
    end
  end
end
