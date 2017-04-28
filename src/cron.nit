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

# CRON tasks system
module cron

import model
import popcorn
import pthreads

redef class AppConfig

	# Screen captures directory
	var captures_dir = "data/"

	# Check `site` and gen screencap in `captures_dir`
	fun check_site(site: Site): Status do
		var status = site.check_status(self)
		var screen = "{captures_dir / (new MongoObjectId).id}.png"
		if site.gen_screencap(screen) then
			status.screencap = screen
		end
		self.status.save status
		return status
	end
end

redef class App

	# Tasks to run
	var tasks = new Array[PopTask]

	# Run all registered tasks
	fun start_tasks do for task in tasks do task.start
end

# An abstract Popcorn task
abstract class PopTask
	super Thread

	# App configuration so we can access App related services
	var config: AppConfig

	redef fun main do return null
end

# Check all the registered sites
class CheckSites
	super PopTask

	redef fun main do
		loop
			for site in config.sites.find_all do
				config.check_site(site)
			end
			5.0.sleep
		end
	end
end
