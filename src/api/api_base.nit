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

module api_base

import model
import popcorn
import popcorn::pop_validation

# A basic API handler
abstract class APIHandler
	super Handler

	# Kind of objects returned by `deserialize_body`.
	type BODY: Serializable

	# App config
	var config: AppConfig

	# Deserialize the request body
	fun deserialize_body(req: HttpRequest, res: HttpResponse): nullable BODY do
		var post = req.body
		var deserializer = new JsonDeserializer(post)
		var form = new_body_object(deserializer)
		if not deserializer.errors.is_empty then
			res.api_error("Cannot process request body", 400)
			# print deserializer.errors.join("\n")
			# print post.write_to_string
			return null
		end
		return form
	end

	# Create a new `BODY` object from a deserializer
	fun new_body_object(deserializer: JsonDeserializer): BODY is abstract

	# Json validator used to validate POST/PUT inputs
	#
	# See `validate`
	fun validator: ObjectValidator is abstract

	# Validate POST input with `validator`
	#
	# * Returns the validated string input is the result of the validation is ok.
	# * Sends HTTP 400 and returns `null` if something went wrong.
	fun validate(req: HttpRequest, res: HttpResponse): nullable String do
		var body = req.body
		if not validator.validate(body) then
			res.json(validator.validation, 400)
			# print validator.validation.to_json
			return null
		end
		return body
	end

	# Paginate results
	fun paginate(results: JsonArray, count: Int, page, limit: nullable Int): JsonObject do
		if page == null or page <= 0 then page = 1
		if limit == null or limit <= 0 then limit = 20

		var max = count / limit
		if page > max then page = max

		var lstart = (page - 1) * limit
		var lend = limit
		if lstart + lend > count then lend = count - lstart

		var res = new JsonObject
		res["page"] = page
		res["limit"] = limit
		res["results"] = results
		res["max"] = max
		res["total"] = count
		return res
	end
end

redef class HttpResponse

	# Return an api error as a json object
	fun api_error(message: String, status: Int) do
		var obj = new JsonObject
		obj["status"] = status
		obj["message"] = message
		json(obj, status)
	end
end

redef class ValidationResult
	redef fun core_serialize_to(v) do
		v.serialize_attribute("has_error", has_error)
		v.serialize_attribute("errors", errors)
	end
end
