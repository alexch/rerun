# Rerun

<http://github.com/alexch/rerun>

Launches your app, then watches the filesystem. If a relevant file
changes, then it restarts your app.

Currently only *.rb files are watched. This is pretty lame so it will
change soon.

If you're on Mac OS X, it uses the built-in facilities for monitoring
the filesystem, so CPU use is very light. And if you have "growlnotify"
available on the PATH, it sends notifications to growl in addition to
the console. Here's how to install
[growlnotify](http://growl.info/documentation/growlnotify.php):

>    In your shell, cd to the directory on the Growl disk image
>    containing growlnotify, and type ./install.sh. That script
>    will install growlnotify to /usr/local/bin and the manpage
>    to /usr/local/man.

Rerun does not work on Windows. Sorry, but you can't do much relaunching
without "fork".

# Installation:

        sudo gem install rerun

If you want to use the latest version, grab it off Github:

        gem sources -a http://gems.github.com/
        sudo gem install alexch-rerun

I'll bump the version on Github for release candidates, and deploy to
Rubyforge only when it's had some time to bake.

# Usage: 

        rerun [options] cmd

For example, if you're running a Sinatra app whose main file is
app.rb:

        rerun app.rb
        
Or if you're running a Rack app that's configured in config.ru
but you want it on port 4000 and in debug mode:

        rerun "thin start --debug --port=4000 -R config.ru"        

# Options:

--dir directory to watch (default = ".")

Also --version and --help.

# To Do:

* If the cmd is, or starts with, a ".rb" file, then run it with ruby
* Watch arbitrary file types via globbing
* Allow arbitrary sets of directories and file types, possibly with "include" and "exclude" sets
* ".rerun" file to specify options per project or in $HOME.
* Test on Linux.
* Test on Mac without Growlnotify.
* Merge with Kicker (using it as a library and writing a Rerun recipe)

# Other projects that do similar things

Restartomatic: <http://github.com/adammck/restartomatic>

Shotgun: <http://github.com/rtomayko/shotgun>

Rack::Reloader middleware: <http://github.com/rack/rack/blob/5ca8f82fb59f0bf0e8fd438e8e91c5acf3d98e44/lib/rack/reloader.rb>

and the Sinatra FAQ has a discussion at <http://www.sinatrarb.com/faq.html#reloading>

Kicker: <http://github.com/alloy/kicker/>

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
need to. This is fine if you're loading a single file, but my web
pages all load other files (CSS, JS, media) and that adds up quickly.
The developers of shotgun are probably using caching or a front web
server so this doesn't affect them too much.

YMMV!

# Why would I use this instead of Rack::Reloader?

Rack::Reloader is certifiably beautiful code, and is a very elegant use
of Rack's middleware architecture. But because it relies on the
LOADED_FEATURES variable, it only reloads .rb files that were 'require'd,
not 'load'ed. That leaves out (non-Erector) template files, and also,
the way I was doing it, sub-actions (see
[this thread](http://groups.google.com/group/sinatrarb/browse_thread/thread/7329727a9296e96a#
)).

Rack::Reloader also doesn't reload configuration changes or redo other
things that happen during app startup. Rerun takes the attitude that if
you want to restart an app, you should just restart the whole app. You know?

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

Rerun: Alex Chaffee, <mailto:alex@stinky.com>, <http://github.com/alexch/>

Based upon and/or inspired by:

Shotgun: <http://github.com/rtomayko/shotgun>

Rspactor: <http://github.com/mislav/rspactor>
(In turn based on http://rails.aizatto.com/2007/11/28/taming-the-autotest-beast-with-fsevents/ )

FileSystemWatcher: <http://paulhorman.com/filesystemwatcher/>

Patches by:

David Billskog <billskog@gmail.com>

# License

Open Source MIT License. See "LICENSE" file.
