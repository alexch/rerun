# Rerun

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

Restartomatic
http://github.com/adammck/restartomatic

Shotgun
http://github.com/rtomayko/shotgun

# License

Open Source MIT License. See "LICENSE" file.
