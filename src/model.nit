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
import popcorn::pop_auth_basic
import http_status

redef class AppConfig

	# Mongodb
	redef var default_db_name = "watchdog"

	# User repository (also used for auth)
	var users = new UserRepo(db.collection("users")) is lazy

	redef var auth_repo = users is lazy

	# Site repository
	var sites = new SiteRepo(db.collection("sites")) is lazy

	# Site status repository
	var status = new StatusRepo(db.collection("status")) is lazy
end

redef class User
	serialize

	redef var id = login is lateinit, serialize_as "_id"

	# Find sites owned by `self`
	fun sites(config: AppConfig): Array[Site] do
		return config.sites.find_by_user(self)
	end

	# Find site owned by `self` with `siteid`
	fun site(config: AppConfig, siteid: String): nullable Site do
		return config.sites.find_site_by_user(self, siteid)
	end
end

# The user repository used to implement the AuthRepository methods
class UserRepo
	super AuthRepository
	super MongoRepository[User]

	redef fun find_by_login(login) do
		return find((new MongoMatch).eq("login", login))
	end

	redef fun find_by_email(email) do
		return find((new MongoMatch).eq("email", email))
	end
end

# A site to check
class Site
	super RepoObject
	serialize

	# Owner user id
	var user: String

	# Site URL
	var url: String is writable

	# Site name (used as label in frontend)
	var name: nullable String is writable

	# Get all the statuses for `self` sorted by reverse timestamp
	fun status(config: AppConfig, s, l: nullable Int): Array[Status] do
		return config.status.find_by_site(self, s, l)
	end

	# Count all the statuses for `self`
	fun count_status(config: AppConfig): Int do
		return config.status.count_by_site(self)
	end

	# Get the last status for `self` (the most recent)
	fun last_status(config: AppConfig): nullable Status do
		return config.status.last_by_site(self)
	end

	# Check the site status
	fun check_status(config: AppConfig): Status do
		var clock = new Clock
		var res = send_request
		var time = clock.total

		var code = -1
		var body = "not run"
		var status = "Unknown"
		if res isa CurlResponseSuccess then
			code = res.status_code
			status = config.code2status(code)
			body = res.body_str
		else if res isa CurlResponseFailed then
			code = res.error_code
			status = res.error_msg
			body = res.error_msg
		end
		return new Status(id, time, code, status, body)
	end

	# Perform Curl HTTP request
	private fun send_request: CurlResponse do
		var req = new CurlHTTPRequest(url)
		return req.execute
	end

	# Gen a screencapture and return its id or null if the url cannot be reached
	fun gen_screencap(path: String): Bool do
		return sys.system("phantomjs src/screencap.js \"{url}\" \"{path}\" > /dev/null 2>&1 ").to_i == 0
	end

	redef fun to_s do return url
end

# Site repository
class SiteRepo
	super MongoRepository[Site]

	# Find all status for `user` by order of creation
	fun find_by_user(user: User): Array[Site] do
		return find_all((new MongoMatch).eq("user", user.id))
	end

	# Find `siteid` for `user` or null if not found
	fun find_site_by_user(user: User, siteid: String): nullable Site do
		return find((new MongoMatch).eq("user", user.id).eq("_id", siteid))
	end
end

# A status for a site at a given timestamp
class Status
	super RepoObject
	serialize

	# Site id
	var site: String

	# Timestamp of the status check
	var timestamp: Int = get_millitime

	# Site response time in seconds
	var response_time: Float

	# Site response status code
	var response_code: Int

	# Site response status message translated from code
	var response_status: String

	# Site response body
	var response_body: String

	# Site screencap url if any
	var screencap: nullable String is writable

	# Is the status between 100 and 399? (used for frontend)
	var is_ok: Bool is lazy do return response_code >= 100 and response_code < 400

	redef fun to_s do return "{timestamp} {response_code} ({response_time}s)"
end

# Status repository
class StatusRepo
	super MongoRepository[Status]

	redef fun find_all(q, s, l) do
		var match = new MongoMatch
		if q != null then
			for k, v in q do match.eq(k, v)
		end

		var orderby = new JsonObject
		orderby["timestamp"] = -1

		var json = collection.aggregate(
		(new MongoPipeline).match(match).sort(orderby).skip(s).limit(l))

		var res = new Array[Status]
		for obj in json do
			var status = deserialize(obj.to_json)
			if status == null then continue
			res.add status
		end
		return res
	end

	# Find all status for `site` (by reversed timestamp order)
	fun find_by_site(site: Site, s, l: nullable Int): Array[Status] do
		return find_all((new MongoMatch).eq("site", site.id), s, l)
	end

	# Count all status for `site`
	fun count_by_site(site: Site): Int do
		return count((new MongoMatch).eq("site", site.id))
	end

	# Find last status for `site` (the most recent)
	fun last_by_site(site: Site): nullable Status do
		var last = find_by_site(site, 0, 1)
		if last.is_empty then return null
		return last.first
	end
end
