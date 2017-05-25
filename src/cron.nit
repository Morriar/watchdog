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

	# Send and alert to `user` about the `status` of `site`
	fun send_alert(user: User, site: Site, status: Status) do
		var subject = "watchdog alert for {site.name or else site.url}"
		var body = """
<h1>Hi {{{user.login}}},</h1>

<p>
	There seems to be a problem with
	<a href='{{{site.name or else site.url}}}'>{{{site.url}}}</a></p>
</p>
<p>The service responded <b>{{{status.response_code}}}</b>.</p>"""

		if status.screencap != null then
			body += """
<p>
	Here a screeencap of your service:
	<img src='{{{app_hostname}}}/{{{status.screencap.as(not null)}}}' />
</p>"""
		end

		body += """
<small>
	If you don't want to receive this email again,
	disable alerts in your <a href='{{{app_hostname}}}/settings'>settings page</a>.
</small>"""

		var mail = new Mail(email_from, subject, body)
		mail.to.add user.email
		mail.header["Content-Type"] = "text/html"
	    mail.send
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

	# Send an alert to `user` about the `status` of `site`
	fun send_alert(user: User, site: Site, status: Status) do
		if not user.email_is_valid then return
		if not user.alerts or not site.alerts then return

		var last_alert = site.last_alert
		var now = get_time * 1000
		var del = 86400 * 1000
		if last_alert != null and last_alert.timestamp + del > now then return
		config.send_alert(user, site, status)
	end

	redef fun main do
		loop
			for user in config.auth_repo.find_all do
				for site in user.sites(config) do
					var status = config.check_site(site)
					if not status.is_ok then send_alert(user, site, status)
				end
			end
			5.0.sleep
		end
	end
end

redef class User
	serialize

	# Send alerts to this user?
	var alerts = false is writable
end

redef class Site
	serialize

	# Send alerts about this site?
	var alerts = false is writable

	# Last status send as alert or null if any
	var last_alert: nullable Status = null
end
