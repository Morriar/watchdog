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
module api

import popcorn
import model

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
		return status
	end
end

# API Router
class APIRouter
	super Router

	# App config
	var config: AppConfig

	redef init do
		super
		use("/sites", new APISites(config))
		use("/sites/:siteid", new APISite(config))
		use("/sites/:siteid/status", new APIStatuses(config))
		use("/sites/:siteid/status/:statusid", new APIStatus(config))

		use("/*", new APIErrorHandler(config))
	end
end

# A basic API handler
abstract class APIHandler
	super Handler

	# App config
	var config: AppConfig

	# Deserialize a site form
	fun deserialize_site(req: HttpRequest, res: HttpResponse): nullable SiteForm do
		var post = req.body
		var deserializer = new JsonDeserializer(post)
		var form = new SiteForm.from_deserializer(deserializer)
		if not deserializer.errors.is_empty then
			res.error 400
			print "Error deserializing site"
			print deserializer.errors.join("\n")
			print post.write_to_string
			return null
		end
		return form
	end

	# Paginate results
	fun paginate(results: JsonArray, page, limit: nullable Int): JsonObject do
		if page == null or page <= 0 then page = 1
		if limit == null or limit <= 0 then limit = 20

		var max = (results.length / limit) + 1
		if page > max then page = 1

		var lstart = (page - 1) * limit
		var lend = limit
		if lstart + lend > results.length then lend = results.length - lstart

		var res = new JsonObject
		res["page"] = page
		res["limit"] = limit
		res["results"] = new JsonArray.from(results.subarray(lstart, lend))
		res["max"] = max
		res["total"] = results.length
		return res
	end
end

# Error handler
class APIErrorHandler
	super APIHandler

	redef fun all(req, res) do res.api_error(404, "Not found")
end

# /sites
#
# GET: get all the sites
class APISites
	super APIHandler

	redef fun get(req, res) do
		var arr = new JsonArray
		for site in config.sites.find_all do
			var form = new SiteForm(site.id, site.url, site.name)
			form.last_status = config.check_site(site)
			arr.add form
		end
		res.json arr
	end

	redef fun post(req, res) do
		var form = deserialize_site(req, res)
		if form == null then return
		var site = new Site(form.url, form.name)
		config.sites.save site
		res.json site
	end
end

# /sites/:siteid
#
# GET: get the site for `siteid`
class APISite
	super APIHandler

	# Get the site for `:siteid`
	fun get_site(req: HttpRequest, res: HttpResponse): nullable Site do
		var siteid = req.param("siteid")
		if siteid == null then
			res.api_error(400, "Missing :siteid")
			return null
		end
		var site = config.sites.find_by_id(siteid)
		if site == null then
			res.api_error(404, "Site `{siteid}` not found")
			return null
		end
		return site
	end

	redef fun get(req, res) do
		var site = get_site(req, res)
		if site == null then return
		var form = new SiteForm(site.id, site.url, site.name)
		form.last_status = config.check_site(site)
		res.json form
	end

	redef fun post(req, res) do
		var site = get_site(req, res)
		if site == null then return
		var form = deserialize_site(req, res)
		if form == null then return
		site.name = form.name
		site.url = form.url
		config.sites.save site
		res.json site
	end

	redef fun delete(req, res) do
		var site = get_site(req, res)
		if site == null then return
		config.sites.remove_by_id(site.id)
		res.json site
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
		var site = get_site(req, res)
		if site == null then return
		var arr = new JsonArray.from(site.status(config))
		res.json paginate(arr, page, limit)
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
			res.api_error(400, "Missing :statusid")
			return null
		end
		var status = config.status.find_by_id(statusid)
		if status == null then
			res.api_error(404, "Status `{statusid}` not found")
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
	super Jsonable
	serialize

	# Site id or null if new
	var id: nullable String

	# Site url
	var url: String

	# Site name (optional)
	var name: nullable String

	# Site last status if any
	var last_status: nullable Status
end

redef class HttpResponse

	# Return an api error as a json object
	fun api_error(status: Int, message: String) do
		var obj = new JsonObject
		obj["status"] = status
		obj["message"] = message
		json(obj, status)
	end
end
