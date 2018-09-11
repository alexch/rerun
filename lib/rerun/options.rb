require 'optparse'
require 'pathname'
require 'rerun/watcher'
require 'rerun/system'

libdir = "#{File.expand_path(File.dirname(File.dirname(__FILE__)))}"

$spec = Gem::Specification.load(File.join(libdir, "..", "rerun.gemspec"))

module Rerun
  class Options

    extend Rerun::System

    # If you change the default pattern, please update the README.md file -- the list appears twice therein, which at the time of this comment are lines 17 and 119
    DEFAULT_PATTERN = "**/*.{rb,js,coffee,css,scss,sass,erb,html,haml,ru,yml,slim,md,feature,c,h}"
    DEFAULT_DIRS = ["."]

    DEFAULTS = {
      :background => false,
      :dir => DEFAULT_DIRS,
      :force_polling => false,
      :ignore => [],
      :ignore_dotfiles => true,
      :name => Pathname.getwd.basename.to_s.capitalize,
      :notify => true,
      :pattern => DEFAULT_PATTERN,
      :quiet => false,
      :signal => (windows? ? "TERM,KILL" : "TERM,INT,KILL"),
      :verbose => false,
      :wait => 2,
    }

    def self.parse args: ARGV, config_file: nil

      default_options = DEFAULTS.dup
      options = {
        ignore: []
      }

      if config_file && File.exist?(config_file)
        require 'shellwords'
        config_args = File.read(config_file).shellsplit
        args = config_args + args
      end

      option_parser = OptionParser.new("", 24, '  ') do |o|
        o.banner = "Usage: rerun [options] [--] cmd"

        o.separator ""
        o.separator "Launches an app, and restarts it when the filesystem changes."
        o.separator "See http://github.com/alexch/rerun for more info."
        o.separator "Version: #{$spec.version}"
        o.separator ""
        o.separator "Options:"

        o.on("-d dir", "--dir dir", "directory to watch, default = \"#{DEFAULT_DIRS}\".  Specify multiple paths with ',' or separate '-d dir' option pairs.") do |dir|
          elements = dir.split(",")
          options[:dir] = (options[:dir] || []) + elements
        end

        # todo: rename to "--watch"
        o.on("-p pattern", "--pattern pattern", "file glob to watch, default = \"#{DEFAULTS[:pattern]}\"") do |pattern|
          options[:pattern] = pattern
        end

        o.on("-i pattern", "--ignore pattern", "file glob(s) to ignore. Can be set many times. To ignore a directory, you must append '/*' e.g. --ignore 'coverage/*' . Globs do not match dotfiles by default.") do |pattern|
          options[:ignore] += [pattern]
        end

        o.on("--[no-]ignore-dotfiles", "by default, file globs do not match files that begin with a dot. Setting --no-ignore-dotfiles allows you to monitor a relevant file like .env, but you may also have to explicitly --ignore more dotfiles and dotdirs.") do |value|
          options[:ignore_dotfiles] = value
        end

        o.on("-s signal", "--signal signal", "terminate process using this signal. To try several signals in series, use a comma-delimited list. Default: \"#{DEFAULTS[:signal]}\"") do |signal|
          options[:signal] = signal
        end

        o.on("-w sec", "--wait sec", "after asking the process to terminate, wait this long (in seconds) before either aborting, or trying the next signal in series. Default: #{DEFAULTS[:wait]} sec")

        o.on("-r", "--restart", "expect process to restart itself, so just send a signal and continue watching. Sends the HUP signal unless overridden using --signal") do |signal|
          options[:restart] = true
          default_options[:signal] = "HUP"
        end

        o.on("-x", "--exit", "expect the program to exit. With this option, rerun checks the return value; without it, rerun checks that the process is running.") do |value|
          options[:exit] = value
        end

        o.on("-c", "--clear", "clear screen before each run") do |value|
          options[:clear] = value
        end

        o.on("-b", "--background", "disable on-the-fly keypress commands, allowing the process to be backgrounded") do |value|
          options[:background] = value
        end

        o.on("-n name", "--name name", "name of app used in logs and notifications, default = \"#{DEFAULTS[:name]}\"") do |name|
          options[:name] = name
        end

        o.on("--[no-]force-polling", "use polling instead of a native filesystem scan (useful for Vagrant)") do |value|
          options[:force_polling] = value
        end

        o.on("--no-growl", "don't use growl [OBSOLETE]") do
          options[:growl] = false
          $stderr.puts "--no-growl is obsolete; use --no-notify instead"
          return
        end

        o.on("--[no-]notify [notifier]", "send messages through a desktop notification application. Supports growl (requires growlnotify), osx (requires terminal-notifier gem), and notify-send on GNU/Linux (notify-send must be installed)") do |notifier|
          notifier = true if notifier.nil?
          options[:notify] = notifier
        end

        o.on("-q", "--[no-]quiet", "don't output any logs") do |value|
          options[:quiet] = value
        end

        o.on("--[no-]verbose", "log extra stuff like PIDs (unless you also specified `--quiet`") do |value|
          options[:verbose] = value
        end

        o.on_tail("-h", "--help", "--usage", "show this message and immediately exit") do
          puts o
          return
        end

        o.on_tail("--version", "show version and immediately exit") do
          puts $spec.version
          return
        end

      end

      puts option_parser if args.empty?
      option_parser.parse! args
      options = default_options.merge(options)
      options[:cmd] = args.join(" ").strip # todo: better arg word handling

      options
    end
  end

end
