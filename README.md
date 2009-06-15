# Rerun

<http://github.com/alexch/rerun>

Launches your app, then watches the filesystem. If a relevant file
changes, then it restarts your app.

Currently only *.rb files are watched, anywhere under the current
directory (.). This is pretty lame so it will change soon.

If you're on Mac OS X, it uses the built-in facilities for monitoring
the filesystem, so CPU use is very light.  

If you have "growlcmd" available on the PATH, it sends notifications to
growl in addition to the console.

# Usage: 

        rerun [options] cmd

# Options:

Only --version and --help so far.

# To Do:

* Allow arbitrary sets of directories and file types, possibly with "include" and "exclude" sets
* ".rerun" file to specify options per project or in $HOME.
* Test on Windows and Linux.

# Other projects that do similar things

Restartomatic: <http://github.com/adammck/restartomatic>

Shotgun: <http://github.com/rtomayko/shotgun>

# Why would I use this instead of Shotgun?

Shotgun does a "fork" after the web framework has loaded but before your application is
loaded. It then loads your app, processes a single request in the child process, then exits the child process.

Rerun launches the whole app, then when it's time to restart, uses "kill" to shut it
down and starts the whole thing up again from scratch. 

So rerun takes somewhat longer than Shotgun to restart the app, but does it much less
frequently. And once it's running it behaves more normally and consistently with your
production app.

Also, Shotgun reloads the app on every request, even if it doesn't need to. This is
fine if you're loading a single file, but my web pages all load other files (CSS, JS,
media) and that adds up quickly. The developers of shotgun are probably using caching
or a front web server so this doesn't affect them too much.

YMMV!

# Contact

Alex Chaffee, <mailto:alex@stinky.com>, <http://github.com/alexch/>

# License

Open Source MIT License. See "LICENSE" file.
