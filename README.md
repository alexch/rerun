# Rerun

<http://github.com/alexch/rerun>

Rerun launches your program, then watches the filesystem. If a relevant file
changes, then it restarts your program.

Rerun works for both long-running processes (e.g. apps) and short-running ones
(e.g. tests). It's basically a no-frills command-line alternative to Guard,
Shotgun, Autotest, etc. that doesn't require config files and works on any
command, not just Ruby programs.

Rerun's advantage is its simple design. Since it uses `exec` and the standard
Unix `SIGINT` and `SIGKILL` signals, you're sure the restarted app is really
acting just like it was when you ran it from the command line the first time.

By default only `*.{rb,js,css,scss,sass,erb,html,haml,ru}` files are watched.
Use the `--pattern` option if you want to change this.

As of version 0.7.0, we use the Listen gem, which tries to use your OS's
built-in facilities for monitoring the filesystem, so CPU use is very light.

Rerun does not work on Windows. Sorry, but you can't do much relaunching
without "fork".

# Installation:

        gem install rerun

("sudo" may be required on older systems, but try it without sudo first.)

If you are using RVM you might want to put this in your global gemset so it's
available to all your apps. (There really should be a better way to distinguish
gems-as-libraries from gems-as-tools.)

        rvm @global do gem install rerun

# Usage:

        rerun [options] [--] cmd

For example, if you're running a Sinatra app whose main file is `app.rb`:

        rerun ruby app.rb

If the first part of the command is a `.rb` filename, then `ruby` is
optional, so the above can also be accomplished like this:

        rerun app.rb

Rails doesn't automatically notice all config file changes, so you can force it
to restart when you change a config file like this:

        rerun --dir config rails s

Or if you're using Thin to run a Rack app that's configured in config.ru
but you want it on port 4000 and in debug mode, and only want to watch
the `app` subdirectory:

        rerun --dir app -- thin start --debug --port=4000 -R config.ru

The `--` is to separate rerun options from cmd options. You can also
use a quoted string for the command, e.g.

        rerun --dir app "thin start --debug --port=4000 -R config.ru"

Rackup can also be used to launch a Rack server, so let's try that:

        rerun -- rackup --port 4000 config.ru

Want to mimic [autotest](https://github.com/grosser/autotest)? Try

        rerun -x rake

or

        rerun -cx rspec

And if you're using [Spork](https://github.com/sporkrb/spork) with Rails, you
need to [restart your spork server](https://github.com/sporkrb/spork/issues/201)
whenever certain Rails environment files change, so why not put this in your
Rakefile...

    desc "run spork (via rerun)"
    task :spork do
      sh "rerun --pattern '{Gemfile,Gemfile.lock,spec/spec_helper.rb,.rspec,spec/factories/**,config/environment.rb,config/environments/test.rb,config/initializers/*.rb,lib/**/*.rb}' -- spork"
    end

and start using `rake spork` to launch your spork server?

(If you're using Guard instead of Rerun, check out
[guard-spork](https://github.com/guard/guard-spork)
for a similar solution.)

How about regenerating your HTML files after every change to your
[Erector](http://erector.rubyforge.org) widgets?

        rerun -x erector --to-html my_site.rb

Use Heroku Cedar? `rerun` is now compatible with `foreman`. Run all your
Procfile processes locally and restart them all when necessary.

        rerun foreman start

# Options:

`--dir` directory to watch (default = ".")

`--pattern` glob to match inside directory. This uses the Ruby Dir glob style -- see <http://www.ruby-doc.org/core/classes/Dir.html#M002322> for details.
By default it watches files ending in: `rb,js,css,scss,sass,erb,html,haml,ru`.
It also ignores directories named `.rbx .bundle .git .svn log tmp vendor` and files named `.DS_Store`.

`--signal` (or -s) use specified signal (instead of the default SIGTERM) to terminate the previous process.
This may be useful for forcing the respective process to terminate as quickly as possible.
(`--signal KILL` is the equivalent of `kill -9`)

`--clear` (or -c) clear the screen before each run

`--exit` (or -x) expect the program to exit. With this option, rerun checks the return value; without it, rerun checks that the launched process is still running.

Also --version and --help, naturally.

# Growl Notifications

If you have `growlnotify` available on the `PATH`, it sends notifications to
growl in addition to the console.

Download [growlnotify here](http://growl.info/downloads.php#generaldownloads)
now that Growl has moved to the App Store.

# On-The-Fly Commands

While the app is (re)running, you can make things happen by pressing keys:

* **r** -- restart (as if a file had changed)
* **c** -- clear the screen
* **x** or **q** -- exit (just like control-C)

# Signals

The current algorithm for killing the process is:

* send [SIGTERM](http://en.wikipedia.org/wiki/SIGTERM)
* if that doesn't work after 4 seconds, send SIGINT (aka control-C)
* if that doesn't work after 2 more seconds, send SIGKILL (aka kill -9)

This seems like the most gentle and unixy way of doing things, but it does
mean that if your program ignores SIGTERM, it takes an extra 4 to 6 seconds to
restart.

# To Do:

* Cooldown (so if a dozen files appear in a burst, say from 'git pull', it only restarts once)
* If the last element of the command is a `.ru` file and there's no other command then use `rackup`
* Exclude files beginning with a dot, unless the pattern explicitly says to include them
* Allow multiple sets of directories and patterns
* --exclude pattern
* ".rerun" file to specify options per project or in $HOME.
* Test on Linux.
* On OS X, use a C library using growl's developer API <http://growl.info/developer/>
* Use growl's AppleScript or SDK instead of relying on growlnotify
* "Failed" icon
* Get Rails icon working
* Figure out an algorithm so "-x" is not needed (if possible)
* Specify (or deduce) port to listen for to determine success of a web server launch
* Make sure to pass through quoted options correctly to target process [bug]
* Make it work on Windows, like Guard now does. See
  * https://github.com/guard/guard/issues/59
  * https://github.com/guard/guard/issues/27
* Optionally do "bundle install" before and "bundle exec" during launch
* Option to specify signal(s) to try before SIGKILL (kill -9)

# Other projects that do similar things

* Restartomatic: <http://github.com/adammck/restartomatic>
* Shotgun: <http://github.com/rtomayko/shotgun>
* Rack::Reloader middleware: <http://github.com/rack/rack/blob/5ca8f82fb59f0bf0e8fd438e8e91c5acf3d98e44/lib/rack/reloader.rb>
* The Sinatra FAQ has a discussion at <http://www.sinatrarb.com/faq.html#reloading>
* Kicker: <http://github.com/alloy/kicker/>
* Watchr: <https://github.com/mynyml/watchr>
* Guard: <http://github.com/guard/guard>
* Autotest: <https://github.com/grosser/autotest>

# Why would I use this instead of Shotgun?

Shotgun does a "fork" after the web framework has loaded but before
your application is loaded. It then loads your app, processes a
single request in the child process, then exits the child process.

Rerun launches the whole app, then when it's time to restart, uses
"kill" to shut it down and starts the whole thing up again from
scratch.

So rerun takes somewhat longer than Shotgun to restart the app, but
does it much less frequently. And once it's running it behaves more
normally and consistently with your production app.

Also, Shotgun reloads the app on every request, even if it doesn't
need to. This is fine if you're loading a single file, but if your web
pages all load other files (CSS, JS, media) then that adds up quickly.
(I can only assume that the developers of shotgun are using caching or a
front web server so this isn't a pain point for them.)

And hey, does Shotgun reload your Worker processes if you're using Foreman and
a Procfile? I'm pretty sure it doesn't.

YMMV!

# Why would I use this instead of Rack::Reloader?

Rack::Reloader is certifiably beautiful code, and is a very elegant use
of Rack's middleware architecture. But because it relies on the
LOADED_FEATURES variable, it only reloads .rb files that were 'require'd,
not 'load'ed. That leaves out (non-Erector) template files, and also,
at least the way I was doing it, sub-actions (see
[this thread](http://groups.google.com/group/sinatrarb/browse_thread/thread/7329727a9296e96a#
)).

Rack::Reloader also doesn't reload configuration changes or redo other
things that happen during app startup. Rerun takes the attitude that if
you want to restart an app, you should just restart the whole app. You know?

# Why would I use this instead of Guard?

Guard is very powerful but requires some up-front configuration.
Rerun is meant as a no-frills command-line alternative requiring no knowledge
of Ruby nor config file syntax.

# Why did you write this?

I've been using [Sinatra](http://sinatrarb.com) and loving it. In order
to simplify their system, the Rat Pack just removed auto-reloading from
Sinatra proper. I approve of this: a web application framework should be
focused on serving requests, not on munging Ruby ObjectSpace for
dev-time convenience. But I still wanted automatic reloading during
development. Shotgun wasn't working for me (see above) so I spliced
Rerun together out of code from Rspactor, FileSystemWatcher, and Shotgun
-- with a heavy amount of refactoring and rewriting.

# Credits

Rerun: [Alex Chaffee](http://alexchaffee.com), <mailto:alex@stinky.com>, <http://github.com/alexch/>

Based upon and/or inspired by:

* Shotgun: <http://github.com/rtomayko/shotgun>
* Rspactor: <http://github.com/mislav/rspactor>
  * (In turn based on http://rails.aizatto.com/2007/11/28/taming-the-autotest-beast-with-fsevents/ )
* FileSystemWatcher: <http://paulhorman.com/filesystemwatcher/>

## Patches by:

* David Billskog <billskog@gmail.com>
* Jens B <https://github.com/dpree>
* Andrés Botero <https://github.com/anbotero>
* Dreamcat4

# Version History

* v0.7.0
  * uses Listen gem (which uses rb-fsevent for lightweight filesystem snooping)

# License

Open Source MIT License. See "LICENSE" file.
