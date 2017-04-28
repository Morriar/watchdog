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
					name: 'site',
					url: '/sites/{sId}?q&p&n',
					templateUrl: '/views/site.html',
					resolve: {
						site: function(Sites, $q, $stateParams) {
							var d = $q.defer();
							Sites.getSite($stateParams.sId, d.resolve, function() {
								d.resolve()});
							return d.promise;
						},
						status: function(Sites, $q, $stateParams) {
							var d = $q.defer();
							Sites.getStatuses($stateParams.sId, 1, 20, d.resolve, function() {
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
				code2string: {
					100: 'Continue',
					101: 'Switching Protocols',
					102: 'Processing',
					200: 'OK',
					201: 'Created',
					202: 'Accepted',
					203: 'Non-Authoritative Information',
					204: 'No Content',
					205: 'Reset Content',
					206: 'Partial Content',
					207: 'Multi-Status',
					208: 'Already Reported',
					226: 'IM Used',
					300: 'Multiple Choices',
					301: 'Moved Permanently',
					302: 'Found',
					303: 'See Other',
					304: 'Not Modified',
					305: 'Use Proxy',
					306: 'Switch Proxy',
					307: 'Temporary Redirect',
					308: 'Permanent Redirect',
					400: 'Bad Request',
					401: 'Unauthorized',
					402: 'Payment Required',
					403: 'Forbidden',
					404: 'Not Found',
					405: 'Method Not Allowed',
					406: 'Not Acceptable',
					407: 'Proxy Authentication Required',
					408: 'Request Timeout',
					409: 'Conflict',
					410: 'Gone',
					411: 'Length Required',
					412: 'Precondition Failed',
					413: 'Payload Too Large',
					414: 'URI Too Long',
					415: 'Unsupported Media Type',
					416: 'Range Not Satisfiable',
					417: 'Exptectation Failed',
					418: 'I\'m a teapot',
					421: 'Misdirect Request',
					422: 'Unprocessable Entity',
					423: 'Locked',
					424: 'Failed Dependency',
					426: 'Upgrade Required',
					428: 'Precondition Required',
					429: 'Too Many Requests',
					431: 'Request header Fields Too Large',
					451: 'Unavailable For Legal Reasons',
					500: 'Internal Server Error',
					501: 'Not Implemented',
					502: 'Bad Gateway',
					503: 'Service Unavailable',
					504: 'Gateway Time-out',
					505: 'HTTP Version Not Supported',
					506: 'Variant Also Negotiates',
					507: 'Insufficient Storage',
					508: 'Loop Detected',
					510: 'Not Extended',
					511: 'Network Authorization Required',
				}
			}
		}])

		/* Controllers */

		.controller('SitesCtrl', function($scope, Errors, Sites, sites) {
			var vm = this;

			vm.init = function() {
				vm.site = {
					name: '',
					url: ''
				}
			}

			vm.createSite = function() {
				Sites.createSite(vm.site, function(data) {
					vm.init();
					vm.loadSites();
				}, Errors.handleError);
			}

			vm.loadSites = function() {
				Sites.getSites(function(data) {
					vm.sites = data;
				}, Errors.handleError);
			}

			vm.translateStatus = function(code) {
				return Sites.code2string[code];
			}

			$scope.$on('delete-site', function(e, id) {
				Sites.removeSite(id, function(data) {
					vm.loadSites();
				}, Errors.handleError);
			})

			vm.init();
			vm.sites = sites;
		})

		.controller('SiteCtrl', function($stateParams, $scope, $state, Errors, Sites, site, status) {
			var vm = this;

			vm.page = $stateParams.p ? $stateParams.p : 1;
			vm.limit = $stateParams.l ? $stateParams.l : 20;

			vm.editSite = function() {
				Sites.editSite(vm.site.id, vm.site, function(data) {
					vm.site = data;
					vm.edit = false;
				}, Errors.handleError);
			}

			vm.removeSite = function() {
				Sites.removeSite(vm.site.id, function(data) {
					$state.go('home');
				}, Errors.handleError);
			}

			vm.translateStatus = function(code) {
				return Sites.code2string[code];
			}

			vm.loadPage = function(page, limit) {
				Sites.getStatuses(vm.site.id, page, limit,
					function(data) {
						vm.status = data;
					}, function(err) {
						vm.error = err;
					});
			}

			$scope.$on('change-page', function(e, page, limit) {
				vm.loadPage(page, limit);
			})

			vm.site = site;
			vm.status = status;
			vm.edit = false;
		})

		/* Directives */

		.directive('siteStatusPanel', function () {
			return {
				scope: {},
				bindToController: {
					site: '='
				},
				controller: function($scope, Sites) {
					var vm = this;

					vm.delete = function() {
						$scope.$emit('delete-site', vm.site.id);
					}

					vm.translateStatus = function(code) {
						return Sites.code2string[code];
					}
				},
				controllerAs: 'vm',
				restrict: 'E',
				replace: true,
				templateUrl: '/directives/site-status-panel.html'
			};
		})

		.directive('status', function () {
			return {
				scope: {},
				bindToController: {
					status: '='
				},
				controller: function(Sites) {
					this.translateStatus = function(code) {
						return Sites.code2string[code];
					}
				},
				controllerAs: 'vm',
				restrict: 'E',
				replace: true,
				templateUrl: '/directives/status.html'
			};
		})

})();
