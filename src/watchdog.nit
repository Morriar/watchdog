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
import console

class CliConfig
	super AppConfig

	# --screencap path
	var opt_screencap = new OptionString("Take a screen capture and save it under the given name",
		"-s", "--screencap")

	# --repeat X
	var opt_repeat = new OptionInt("Repeat check every X seconds",
		0, "-r", "--repeat")

	# --body
	var opt_body = new OptionBool("Show the response body", "-b", "--body")

	# --no-colors
	var opt_no_colors = new OptionBool("Do not use colors in output", "--no-colors")

	init do
		opts.options.clear
		add_option(opt_help, opt_screencap, opt_repeat, opt_body, opt_no_colors)
	end

	fun cli_status(site: Site, screencap_file: nullable String) do
		var status = site.check_status(self)
		if screencap_file != null then
			if not site.gen_screencap(screencap_file) then
				print "Error generating screencap"
			else
				status.screencap = screencap_file
			end
		end
		print color_status(status)
		if opt_body.value then
			print "Body:\n{status.response_body}"
		end
		if status.screencap != null then
			print "Screen capture generated to {status.screencap.as(not null)}"
		end
	end

	fun color_status(status: Status): String do
		var res = "{status.response_time}s"
		if opt_no_colors.value then
			return "{status.response_code} - {status.response_status} - {res}"
		end
		if not status.is_ok then
			return "{status.response_code.to_s.red} - {status.response_status.red} - {res}"
		end
		return "{status.response_code.to_s.green} - {status.response_status.green} - {res}"
	end
end

var config = new CliConfig
config.parse_options(args)
config.tool_description = "usage: watchdog [options] url"

if config.args.length != 1 then
	config.usage
	exit 1
end

var site = new Site("cli", config.args.first)


var timeout = config.opt_repeat.value
if timeout > 0 then
	print "Checking {site.url} every {timeout} seconds"
	loop
		var screencap = config.opt_screencap.value
		if screencap != null then screencap = "{get_time}.{screencap}"
		config.cli_status(site, screencap)
		timeout.to_f.sleep
	end
else
	print "Checking {site.url}"
	config.cli_status(site, config.opt_screencap.value)
end
