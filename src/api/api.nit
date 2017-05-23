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

module api

import api_users
import api_sites

# API Router
class APIRouter
	super Router

	# App config
	var config: AppConfig

	redef init do
		super
		use("/auth", new AuthBasicRouter(config))
		use("/user", new APIUsersRouter(config))
		use("/sites", new APISitesRouter(config))
		use("/*", new APIErrorHandler(config))
	end
end

# Error handler
class APIErrorHandler
	super APIHandler

	redef fun all(req, res) do res.api_error("Not found", 404)
end
