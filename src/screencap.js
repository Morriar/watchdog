// Copyright 2017 Alexandre Terrasa <alexandre@moz-code.org>.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

"use strict";

var page = require('webpage').create();
var system = require('system');

if (system.args.length != 3) {
	console.log('usage: phantom screencap.js URL filename');
	phantom.exit(1);
}

var address = system.args[1];
var output = system.args[2];

page.open(address, function (status) {
	if (status !== 'success') {
		console.log('Error: unable to access the URL.');
		phantom.exit(1);
	} else {
		window.setTimeout(function () {
			page.viewportSize = { width: 800, height: 600 };
			page.zoomFactor = 0.8;
			page.clipRect = { top: 0, left: 0, width: 800, height: 600 };
			page.paperSize = { width: 800, height: 600 };
			page.render(output);
			phantom.exit();
		}, 200);
	}
});
