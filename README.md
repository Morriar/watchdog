# Watchdog

Watchdog allows you to monitor your web services response time.

~~~bash
$ watchdog http://watchdog.moz-code.org -s screencap.png
Checking http://watchdog.moz-code.org
200 - OK - 0.039s
Screen capture generated to screencap.png
~~~

See the online version on [watchdog.moz-code.org](http://watchdog.moz-code.org)

## Install

Requirements:
* [nit](http://nitlanguage.org)
* [MongoDB](https://docs.mongodb.com).
* [PhantomJS](http://phantomjs.org/)

~~~bash
$ git clone https://github.com/Morriar/watchdog
$ cd watchdog
$ make
~~~

## Web App

The `watchdog_app` provides a web application that allows users to register
and save sites to watch within a CRON.

Running the server:

~~~bash
$ watchdog_app -h localhost -p 3000
~~~

Running with `no-hup`:

~~~bash
make start # starts the server in no-hup
make stop # stop the server
~~~

See [localhost:3000](http://localhost:3000) once started.

## CLI

The `watchdog` CLI allows you to check your service status from the command line.

~~~bash
$ watchdog http://watchdog.moz-code.org
~~~

Options:
~~~bash
usage: watchdog [options] url
	-h, --help        Show this help message
	-s, --screencap   Take a screen capture and save it under the given name
	-r, --repeat      Repeat check every X seconds
	-b, --body        Show the response body
	--no-colors       Do not use colors in output
~~~

Option `--repeat` is compatible with all other:

~~~bash
$ watchdog http://watchdog.moz-code.org -b -r 30 -s screen.png
~~~

The screen capture file name will be appended with the check timestamp.
