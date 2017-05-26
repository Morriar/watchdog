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

import cron
import api

var config = new AppConfig
config.parse_options(args)

if config.help then
	config.usage
	exit 0
end

# Set basic auth config
config.email_from = "Watchdog <watchdog@moz-code.org>"
config.verification_email_subject = "Welcome to watchdog"
config.verification_uri = "http://{config.app_hostname}/api/auth/email"
config.verification_redirection_uri = "/auth/email_activation"
config.verify_emails = true
config.lost_password_email_subject = "Watchdog password reset"
config.lost_password_uri = "http://{config.app_hostname}/auth/reset_password"

var app = new App
app.tasks.add(new CheckSites(config))

app.use_before("/*", new SessionInit)
app.use("/api", new APIRouter(config))
app.use("/data", new StaticHandler("data"))
app.use("/*", new StaticHandler("www", "index.html"))

app.use_after("/*", new ConsoleLog)

app.run_tasks
app.listen(config.app_host, config.app_port)
