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

# Serve model as a REST api
module api_sites

import api_users
import cron

# API Sites Router
class APISitesRouter
	super Router

	# App config
	var config: AppConfig

	redef init do
		super
		use("/", new APISites(config))
		use("/:siteid", new APISite(config))
		use("/:siteid/timeline", new APISiteTimeline(config))
		use("/:siteid/status", new APIStatuses(config))
		use("/:siteid/status/:statusid", new APIStatus(config))
	end
end

# /sites
#
# GET: get all the sites
class APISites
	super APIHandler

	redef type BODY: SiteForm
	redef fun new_body_object(d) do return new SiteForm.from_deserializer(d)
	redef var validator is lazy do return new SiteValidator

	redef fun get(req, res) do
		var user = require_authentification(req, res)
		if user == null then return

		var arr = new JsonArray
		for site in user.sites(config) do
			arr.add new SiteForm(site.id, site.url, site.name, site.alerts, site.last_status(config))
		end
		res.json arr
	end

	redef fun post(req, res) do
		var user = require_authentification(req, res)
		if user == null then return
		var post = validate_body(req, res)
		if post == null then return
		var form = deserialize_body(req, res)
		if form == null then return
		var site = new Site(user.login, form.url, form.name)
		site.alerts = form.alerts
		config.sites.save site
		config.check_site(site)
		res.json site
	end
end

# /sites/:siteid
#
# GET: get the site for `siteid`
class APISite
	super APIHandler

	redef type BODY: SiteForm
	redef fun new_body_object(d) do return new SiteForm.from_deserializer(d)
	redef var validator is lazy do return new SiteValidator

	# Get the site for `:siteid`
	fun get_site(req: HttpRequest, res: HttpResponse): nullable Site do
		var user = require_authentification(req, res)
		if user == null then return null

		var siteid = req.param("siteid")
		if siteid == null then
			res.api_error("Missing :siteid", 400)
			return null
		end
		var site = user.site(config, siteid)
		if site == null then
			res.api_error("Site `{siteid}` not found", 404)
			return null
		end
		return site
	end

	redef fun get(req, res) do
		var site = get_site(req, res)
		if site == null then return
		res.json new SiteForm(site.id, site.url, site.name, site.alerts, site.last_status(config))
	end

	redef fun post(req, res) do
		var site = get_site(req, res)
		if site == null then return
		var post = validate_body(req, res)
		if post == null then return
		var form = deserialize_body(req, res)
		if form == null then return
		site.name = form.name
		site.url = form.url
		site.alerts = form.alerts
		config.sites.save site
		res.json new SiteForm(site.id, site.url, site.name, site.alerts, site.last_status(config))
	end

	redef fun delete(req, res) do
		var site = get_site(req, res)
		if site == null then return
		config.sites.remove_by_id(site.id)
		res.json new SiteForm(site.id, site.url, site.name, site.alerts, site.last_status(config))
	end
end

# /sites/:siteid/timeline
#
# GET: get all the status for `siteid`
class APISiteTimeline
	super APISite

	redef fun get(req, res) do
		var site = get_site(req, res)
		if site == null then return

		var arr = new JsonArray
		for status in site.status(config, 0, 20) do
			var obj = new JsonObject
			obj["timestamp"] = status.timestamp
			obj["time"] = status.response_time
			arr.add obj
		end
		res.json arr
	end
end

# /sites/:siteid/status
#
# GET: get all the status for `siteid`
# POST: ask for a new status update
class APIStatuses
	super APISite

	redef fun get(req, res) do
		var page = req.int_arg("p")
		var limit = req.int_arg("n")
		var skip = null
		if page != null and limit != null then skip = (page - 1) * limit
		var site = get_site(req, res)
		if site == null then return
		var results = new JsonArray.from(site.status(config, skip, limit))
		var count = site.count_status(config)
		res.json paginate(results, count, page, limit)
	end

	redef fun post(req, res) do
		var site = get_site(req, res)
		if site == null then return
		var status = config.check_site(site)
		config.status.save status
		res.json status
	end
end

# /sites/:siteid/status/:statusid
#
# GET: get the status with `statusid`
class APIStatus
	super APISite

	# Get status from `:statusid`
	fun get_status(req: HttpRequest, res: HttpResponse): nullable Status do
		var site = get_site(req, res)
		if site == null then return null
		var statusid = req.param("statusid")
		if statusid == null then
			res.api_error("Missing :statusid", 400)
			return null
		end
		var status = config.status.find_by_id(statusid)
		if status == null then
			res.api_error("Status `{statusid}` not found", 404)
			return null
		end
		return status
	end

	redef fun get(req, res) do
		var status = get_status(req, res)
		if status == null then return
		res.json status
	end
end

# Site form from frontend
class SiteForm
	serialize

	# Site id or null if new
	var id: nullable String

	# Site url
	var url: String

	# Site name (optional)
	var name: nullable String

	# Send alerts for this site?
	var alerts: Bool

	# Site last status if any
	var last_status: nullable Status
end

# Validate a SiteForm input
class SiteValidator
	super ObjectValidator

	redef init do
		add new StringField("name", required=true, min_size=1)
		add new URLField("url", required=true)
	end
end
