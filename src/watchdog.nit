# Copyright 2017 Alexandre Terrasa <alexandre@moz-code.org>.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import model
import popcorn::pop_config

redef class AppConfig

	# --screencap path
	var opt_screencap = new OptionString("Take a screen capture and save it under the given name",
		"-s", "--screencap")

	# --timeout X
	var opt_timeout = new OptionInt("Check site within an infinite loop every X seconds",
		0, "-t", "--timeout")

	# --body
	var opt_body = new OptionBool("Show the response body", "-b", "--body")

	redef init do
		super
		add_option(opt_screencap, opt_timeout, opt_body)
	end
end

var config = new AppConfig
config.parse_options(args)

if config.args.length != 1 then
	print "usage: watchdog [options] url"
	exit 1
end

var site = new Site("cli", config.args.first)


var timeout = config.opt_timeout.value
if timeout > 0 then
	print "Checking {site.url} every {timeout} seconds"
	loop
		var status = site.check_status(config)
		print " {status.response_code} - took {status.response_time}s"
		timeout.to_f.sleep
	end
else
	print "Checking {site.url}\n"
	var status = site.check_status(config)
	var screencap = config.opt_screencap.value
	if screencap != null then
		if not site.gen_screencap(screencap) then
			print "Error generating screencap"
		else
			status.screencap = screencap
		end
	end

	print "Response code: {status.response_code}"
	print "Response time: {status.response_time}s"
	if config.opt_body.value then
		print "Response body: {status.response_body}"
	end
	if status.screencap != null then
		print "Screen capture generated to {status.screencap.as(not null)}"
	end
end
