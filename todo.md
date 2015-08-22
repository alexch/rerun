* use GNTP
  * https://github.com/snaka/ruby_gntp
  * https://github.com/ericgj/groem
  * http://growl.info/documentation/developer/gntp.php

* test stty stuff on other Unixes

* use childprocess

* specify escalation timeout (time between sending SIGTERM and SIGINT)

* also try to kill whatever process is listening to a given port
  (in case it's ignoring or doesn't get the signal from its parent)
  (see http://stackoverflow.com/questions/8105322/foreman-does-not-kill-processes for lsof example)

