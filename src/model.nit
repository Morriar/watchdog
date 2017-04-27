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

# Base class definitions
module model

import curl
import realtime
import popcorn::pop_repos

redef class AppConfig

	# Mongodb
	redef var default_db_name = "watchdog"

	# Site repository
	var sites = new SiteRepo(db.collection("sites")) is lazy

	# Site status repository
	var status = new StatusRepo(db.collection("status")) is lazy
end

# A site to check
#
# ~~~
# var site = new Site("http://nitlanguage.org")
# var status = site.check_status
# assert status.response_status == 200
# ~~~
class Site
	super RepoObject
	serialize

	# Site URL
	var url: String is writable

	# Site name
	var name: nullable String is writable

	# Get all the statuses for `self`
	fun status(config: AppConfig): Array[Status] do
		var res = config.status.find_by_site(self)
		(new StatusComparator).sort(res)
		return res
	end

	# Get the last status for `self`
	fun last_status(config: AppConfig): Status do
		var status = status(config)
		if status.is_empty then
			return check_status(config)
		end
		return status.last
	end

	# Check the site status
	fun check_status(config: AppConfig): Status do
		var clock = new Clock
		var res = send_request
		var time = clock.total

		var code = -1
		var body = "not run"
		if res isa CurlResponseSuccess then
			code = res.status_code
			body = res.body_str
		else if res isa CurlResponseFailed then
			code = res.error_code
			body = res.error_msg
		end
		var status = new Status(id, time, code, body)
		config.status.save status
		return status
	end

	private fun send_request: CurlResponse do
		var req = new CurlHTTPRequest(url)
		return req.execute
	end

	redef fun to_s do return url
end

# Site repository
class SiteRepo
	super MongoRepository[Site]
end

# A status for a site at a given timestamp
class Status
	super RepoObject
	serialize

	# Site id
	var site: String

	# Timestamp of the status check
	var timestamp: Int = get_time * 1000

	# Site response time
	var response_time: Float

	# Site response status code
	var response_code: Int

	# Site response body
	var response_body: String

	# Is the status between 100 and 399? (used for frontend)
	var is_ok: Bool is lazy do return response_code >= 100 and response_code < 400

	redef fun to_s do return "{timestamp} {response_code} ({response_time}s)"
end

# Status repository
class StatusRepo
	super MongoRepository[Status]

	# Find all status for `site`
	fun find_by_site(site: Site): Array[Status] do
		return find_all((new MongoMatch).eq("site", site.id))
	end
end

# Sort site status by timestamp
class StatusComparator
	super Comparator

	redef type COMPARED: Status

	redef fun compare(a, b) do return b.timestamp <=> a.timestamp
end
