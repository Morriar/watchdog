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

# CRON tasks system to check sites periodically
module cron

import model
import popcorn
import popcorn::pop_tasks
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
		var subject = "Watchdog alert for {site.name or else site.url}"
		var body = """
<p>Hi {{{user.login}}},</p>

<p>
	There seems to be a problem with the service
	<a href='{{{site.url}}}'>{{{site.name or else site.url}}}</a>
</p>
<p>The service responded <b>{{{status.response_code}}}: {{{status.response_status}}}</b>.</p>"""

		if status.screencap != null then
			body += """
<p>
	Here a screeencap of your service:<br>
	<img src='http://{{{app_hostname}}}/{{{status.screencap.as(not null)}}}' />
</p>"""
		end

		body += """
<small>
	If you don't want to receive this email again,
	disable alerts in your <a href='http://{{{app_hostname}}}/settings'>settings page</a>.
</small>"""

		var mail = new Mail(email_from, subject, body)
		mail.to.add user.email
		mail.header["Content-Type"] = "text/html"
	    mail.send
	end
end

# Check all the registered sites
class CheckSites
	super PopTask

	# App config
	var config: AppConfig

	# Send an alert to `user` about the `status` of `site`
	fun send_alert(user: User, site: Site, status: Status) do
		if not user.email_is_verified then return
		if not user.alerts or not site.alerts then return

		var last_alert = site.last_alert
		var now = get_time * 1000
		var delay = 24 * 60 * 60 * 1000
		if last_alert != null and last_alert + delay > now then return
		site.last_alert = now
		config.sites.save site
		config.send_alert(user, site, status)
	end

	redef fun main do
		loop
			for user in config.users.find_all do
				for site in user.sites(config) do
					var status = config.check_site(site)
					if not status.is_ok then send_alert(user, site, status)
					0.1.sleep
				end
			end
			3600.sleep
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
	var last_alert: nullable Int = null
end
