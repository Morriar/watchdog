/*
 * Copyright 2017 Alexandre Terrasa <alexandre@moz-code.org>.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

(function() {
	angular
		.module('sites', ['ngSanitize'])

		/* Router */

		.config(function ($stateProvider, $locationProvider) {
			$locationProvider.html5Mode(true);
			$stateProvider
				.state({
					name: 'root.site',
					url: '/sites/{sId}?q&p&n',
					templateUrl: '/views/site.html',
					resolve: {
						site: function(Sites, $q, $stateParams) {
							var d = $q.defer();
							Sites.getSite($stateParams.sId, d.resolve, function() {
								d.resolve()});
							return d.promise;
						}
					},
					controller: 'SiteCtrl',
					controllerAs: 'vm'
				})
		})

		/* Model */

		.factory('Sites', [ '$http', function($http) {
			var apiUrl = '/api';
			return {
				getSites: function(cb, cbErr) {
					$http.get(apiUrl + '/sites')
						.success(cb)
						.error(cbErr);
				},
				createSite: function(data, cb, cbErr) {
					$http.post(apiUrl + '/sites', data)
						.success(cb)
						.error(cbErr);
				},
				getSite: function(id, cb, cbErr) {
					$http.get(apiUrl + '/sites/' + id)
						.success(cb)
						.error(cbErr);
				},
				editSite: function(id, data, cb, cbErr) {
					$http.post(apiUrl + '/sites/' + id, data)
						.success(cb)
						.error(cbErr);
				},
				removeSite: function(id, cb, cbErr) {
					$http.delete(apiUrl + '/sites/' + id)
						.success(cb)
						.error(cbErr);
				},
				getStatuses: function(id, p, n, cb, cbErr) {
					$http.get(apiUrl + '/sites/' + id + '/status?p=' + p + '&n=' + n)
						.success(cb)
						.error(cbErr);
				},
				getTimeline: function(id, p, n, cb, cbErr) {
					$http.get(apiUrl + '/sites/' + id + '/timeline?p=' + p + '&n=' + n)
						.success(cb)
						.error(cbErr);
				}
			}
		}])

		/* Controllers */

		.controller('SitesCtrl', function($scope, $state, Errors, Sites, sites, session) {
			if(!session) {
				$state.go('root.auth.signup', null, { location: false });
				return;
			}

			var vm = this;
			vm.session = session;
			vm.sites = sites;

			vm.init = function() {
				vm.site = {
					name: '',
					url: '',
					alerts: false
				}
			}

			vm.loadSites = function() {
				Sites.getSites(function(data) {
					vm.sites = data;
				}, Errors.handleError);
			}

			$scope.$on('submit-site', function(e, site) {
				Sites.createSite(site, function(data) {
					vm.error = null;
					vm.add = false;
					vm.init();
					vm.loadSites();
					$scope.$emit('alert', {status: 'success', message: 'Site created'})
				}, function(error) { vm.error = error });
			})

			$scope.$on('delete-site', function(e, id) {
				Sites.removeSite(id, function(data) {
					vm.loadSites();
					$scope.$emit('alert', {status: 'success', message: 'Site deleted'})
				}, Errors.handleError);
			})

			vm.init();
		})

		.controller('SiteCtrl', function($stateParams, $scope, $state, Errors, Sites, site, session) {
			if(!session) {
				var r = window.location.href;
				$state.go('root.auth.signin', null, { location: false });
				return;
			}

			if(!site) {
				var r = window.location.href;
				$state.go('root.404', null, { location: false });
				return;
			}

			var vm = this;
			vm.session = session;
			vm.site = site;
			vm.page = $stateParams.p ? $stateParams.p : 1;
			vm.limit = $stateParams.l ? $stateParams.l : 20;
			vm.edit = false;

			vm.removeSite = function() {
				Sites.removeSite(vm.site.id, function(data) {
					$scope.$emit('alert', {status: 'success', message: 'Site deleted'})
					$state.go('root.home');
				}, Errors.handleError);
			}

			vm.loadPage = function(page, limit) {
				Sites.getStatuses(vm.site.id, page, limit,
					function(data) {
						vm.status = data;
					}, Errors.handleError);
			}

			vm.loadTimeline = function() {
				Sites.getTimeline(site.id, 1, 20, function(data) {
					vm.timeline = data;
				}, Errors.handleError);
			}

			$scope.$on('submit-site', function(e, site) {
				Sites.editSite(site.id, site, function(data) {
					vm.error = null;
					vm.site = data;
					vm.edit = false;
					$scope.$emit('alert', {status: 'success', message: 'Site saved'})
				}, function(error) { vm.error = error });
			})

			$scope.$on('change-page', function(e, page, limit) {
				vm.loadPage(page, limit);
			})

			vm.loadPage(1, 20);
			vm.loadTimeline();
		})

		/* Directives */

		.directive('siteForm', function () {
			return {
				scope: {},
				bindToController: {
					new: '=',
					site: '=',
					errors: '='
				},
				controller: function($scope) {
					var vm = this;

					vm.submit = function() {
						$scope.$emit('submit-site', vm.site);
					}
				},
				controllerAs: 'vm',
				restrict: 'E',
				replace: true,
				templateUrl: '/directives/sites/form.html'
			};
		})

		.directive('siteStatusPanel', function () {
			return {
				scope: {},
				bindToController: {
					site: '='
				},
				controller: function($scope) {
					var vm = this;

					vm.delete = function() {
						$scope.$emit('delete-site', vm.site.id);
					}
				},
				controllerAs: 'vm',
				restrict: 'E',
				replace: true,
				templateUrl: '/directives/sites/status-panel.html'
			};
		})

		.directive('siteStatusString', function () {
			return {
				scope: {},
				bindToController: {
					status: '='
				},
				controller: function() {},
				controllerAs: 'vm',
				restrict: 'E',
				replace: true,
				templateUrl: '/directives/sites/status-string.html'
			};
		})

		.directive('siteStatusIcon', function () {
			return {
				scope: {},
				bindToController: {
					status: '='
				},
				controller: function() {},
				controllerAs: 'vm',
				restrict: 'E',
				replace: true,
				templateUrl: '/directives/sites/status-icon.html'
			};
		})

		.directive('siteStatusScreen', function () {
			return {
				scope: {},
				bindToController: {
					status: '='
				},
				controller: function() {},
				controllerAs: 'vm',
				restrict: 'E',
				replace: true,
				templateUrl: '/directives/sites/status-screen.html'
			};
		})

		.directive('status', function () {
			return {
				scope: {},
				bindToController: {
					status: '='
				},
				controller: function() {},
				controllerAs: 'vm',
				restrict: 'E',
				replace: true,
				templateUrl: '/directives/sites/status.html'
			};
		})

		.directive('timegraph', function($filter) {
			return {
				scope: {},
				bindToController: {
					timeline: '='
				},
				controller: function() {},
				link: function($scope, $element) {
					$scope.$watch('vm.timeline', function(timeline) {
						if(!timeline) return;
						update(timeline);
					})

					var update = function(data) {
						// Set the dimensions of the canvas / graph
						var margin = {top: 30, right: 20, bottom: 30, left: 50},
							width = 600 - margin.left - margin.right,
							height = 270 - margin.top - margin.bottom;

						// Set the ranges
						var x = d3.time.scale().range([0, width]);
						var y = d3.scale.linear().range([height, 0]);

						var bisectDate = d3.bisector(function(d) { return -d.date; }).left;

						// Define the axes
						var xAxis = d3.svg.axis().scale(x)
							.orient("bottom").ticks(5)
							.tickFormat(function(d) { return d3.time.format("%H:%M")(d); });

						var yAxis = d3.svg.axis().scale(y)
							.orient("left").ticks(5)
							.innerTickSize(-width)
							.outerTickSize(0)
							.tickFormat(function(d) { return d + " ms"; });

						// Define the line
						var valueline = d3.svg.line()
							.interpolate("monotone")
							.x(function(d) { return x(d.date); })
							.y(function(d) { return y(d.time); });

						var area = d3.svg.area()
							.interpolate("monotone")
							.x(function(d) { return x(d.date); })
							.y0(function(d) { return height; })
							.y1(function(d) { return y(d.time); });

						// Adds the svg canvas
						var svg = d3.select($element[0])
							.append("svg")
								.attr("width", width + margin.left + margin.right)
								.attr("height", height + margin.top + margin.bottom)
							.append("g")
								.attr("transform",
									  "translate(" + margin.left + "," + margin.top + ")");

						// Define the div for the tooltip
						var div = d3.select("body").append("div")
							.attr("class", "tooltip")
							.style("opacity", 0);

						// Get the data
						data.forEach(function(d) {
							d.date = new Date(d.timestamp);
						});

						// Scale the range of the data
						x.domain(d3.extent(data, function(d) { return d.date; }));
						y.domain([0, d3.max(data, function(d) { return d.time; })]);

						// Add the X Axis
						svg.append("g")
							.attr("class", "x axis")
							.attr("transform", "translate(0," + height + ")")
							.call(xAxis);

						// Add the Y Axis
						svg.append("g")
							.attr("class", "y axis")
							.call(yAxis);

						// Add the valueline path.
						svg.append("path")
							.attr("class", "line")
							.attr("d", valueline(data));

						// Add the valueline path.
						svg.append("path")
							.attr("class", "area")
							.attr("d", area(data));

						// Add the scatterplot
						svg.selectAll("dot")
							.data(data)
							.enter().append("circle")
							.attr("r", 3.5)
							.attr("cx", function(d) { return x(d.timestamp); })
							.attr("cy", function(d) { return y(d.time); });

						var focus = svg.append('g').style('display', 'none');
						focus.append('line')
							.attr('id', 'focusLineX')
							.attr('class', 'focus-line');
						focus.append('circle')
							.attr('id', 'focusCircle')
							.attr('r', 3.5)
							.attr('class', 'focus-circle');

						svg.append('rect')
							.attr('class', 'overlay')
							.attr('width', width)
							.attr('height', height)
							.on('mouseover', function() { focus.style('display', null); })
							.on('mousemove', function() {
								var mouse = d3.mouse(this);
								var mouseDate = x.invert(mouse[0]);
								var i = bisectDate(data, -mouseDate);
								var d0 = data[i + 1];
								var d1 = data[i];
								var d = mouseDate - d0.date > d1.date - mouseDate ? d1 : d0;

								var x0 = x(d.date);
								var y0 = y(d.time);

								focus.select('#focusCircle')
									.attr('cx', x0)
									.attr('cy', y0);
								focus.select('#focusLineX')
									.attr('x1', x0).attr('y1', height)
									.attr('x2', x0).attr('y2', y0);

								div.style("opacity", .9);
								div.html(
									'<b>' + d.time + ' ms</b><br>' +
									$filter('date')(d.date, "HH:mm")
								)
								.style("left", ($element[0].offsetLeft + x0 + 10) + "px")
								.style("top", ($element[0].offsetTop + y0 - 19) + "px");
							})
							.on('mouseout', function() {
								focus.style('display', 'none');
								div.style("opacity", 0);
							})
					}
				},
				controllerAs: 'vm',
				restrict: 'E',
				replace: true,
				template: ''
			}
		})

})();
