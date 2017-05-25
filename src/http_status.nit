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

module http_status

import popcorn::pop_config

redef class AppConfig

	# Return the message associated to the HTTP status `code`
	fun code2status(code: Int): String do
		if not codes2status.has_key(code) then return "Unknown"
		return codes2status[code]
	end

	# Associate HTTP status codes to their messages
	var codes2status: Map[Int, String] is lazy do
		var map = new HashMap[Int, String]
		map[100] = "Continue"
		map[101] = "Switching Protocols"
		map[102] = "Processing"
		map[200] = "OK"
		map[201] = "Created"
		map[202] = "Accepted"
		map[203] = "Non-Authoritative Information"
		map[204] = "No Content"
		map[205] = "Reset Content"
		map[206] = "Partial Content"
		map[207] = "Multi-Status"
		map[208] = "Already Reported"
		map[226] = "IM Used"
		map[300] = "Multiple Choices"
		map[301] = "Moved Permanently"
		map[302] = "Found"
		map[303] = "See Other"
		map[304] = "Not Modified"
		map[305] = "Use Proxy"
		map[306] = "Switch Proxy"
		map[307] = "Temporary Redirect"
		map[308] = "Permanent Redirect"
		map[400] = "Bad Request"
		map[401] = "Unauthorized"
		map[402] = "Payment Required"
		map[403] = "Forbidden"
		map[404] = "Not Found"
		map[405] = "Method Not Allowed"
		map[406] = "Not Acceptable"
		map[407] = "Proxy Authentication Required"
		map[408] = "Request Timeout"
		map[409] = "Conflict"
		map[410] = "Gone"
		map[411] = "Length Required"
		map[412] = "Precondition Failed"
		map[413] = "Payload Too Large"
		map[414] = "URI Too Long"
		map[415] = "Unsupported Media Type"
		map[416] = "Range Not Satisfiable"
		map[417] = "Exptectation Failed"
		map[418] = "I\'m a teapot"
		map[421] = "Misdirect Request"
		map[422] = "Unprocessable Entity"
		map[423] = "Locked"
		map[424] = "Failed Dependency"
		map[426] = "Upgrade Required"
		map[428] = "Precondition Required"
		map[429] = "Too Many Requests"
		map[431] = "Request header Fields Too Large"
		map[451] = "Unavailable For Legal Reasons"
		map[500] = "Internal Server Error"
		map[501] = "Not Implemented"
		map[502] = "Bad Gateway"
		map[503] = "Service Unavailable"
		map[504] = "Gateway Time-out"
		map[505] = "HTTP Version Not Supported"
		map[506] = "Variant Also Negotiates"
		map[507] = "Insufficient Storage"
		map[508] = "Loop Detected"
		map[510] = "Not Extended"
		map[511] = "Network Authorization Required"
		return map
	end
end
