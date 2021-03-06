/*
 * Copyright 2017 Alexandre Terrasa <alexandre@moz-code.org>.
 *
 * Licensed under the Apache License, Version 2.0 (the 'License');
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an 'AS IS' BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

(function() {
	angular.module('ng-app', ['ui.router', 'angular-loading-bar', 'auth', 'users', 'sites'])

	/* Config */

	.config(['cfpLoadingBarProvider', function(cfpLoadingBarProvider) {
		cfpLoadingBarProvider.includeSpinner = false;
	}])

	.run(['$anchorScroll', function($anchorScroll) {
		$anchorScroll.yOffset = 80;
	}])

	/* Router */

	.config(function ($stateProvider, $locationProvider) {
		$locationProvider.html5Mode(true);
		$stateProvider
			.state({
				name: 'root',
				abstract: true,
				resolve: {
					session: function(Errors, Auth, $q) {
						var d = $q.defer();
						Auth.auth(d.resolve, function () { d.resolve(null) });
						return d.promise;
					}
				},
				controller: function(session) {
					this.session = session;
				},
				controllerAs: 'vm',
				templateUrl: '/views/root.html'
			})
			.state({
				name: 'root.home',
				url: '/',
				resolve: {
					sites: function(Sites, $q) {
						var d = $q.defer();
						Sites.getSites(d.resolve, function() {d.resolve()});
						return d.promise;
					}
				},
				controller: 'SitesCtrl',
				controllerAs: 'vm',
				templateUrl: '/views/index.html'
			})
			.state({
				name: 'root.404',
				url: '/404',
				templateUrl: '/views/404.html'
			})
			.state({
				name: 'root.otherwise',
				url: '*path',
				templateUrl: '/views/404.html'
			})
	})

	/* Model */

	.factory('Errors', function() {
		return {
			handleError: function(err) {
				console.log(err);
			}
		}
	})

	/* Directives */

	.directive('panel404', function() {
		return {
			scope: {},
			templateUrl: '/directives/404-panel.html',
			restrict: 'E',
			replace: true
		};
	})

	.directive('uiAlerts', ['$rootScope', function($rootScope) {
		return {
			scope: {},
			bindToController: {},
			restrict: 'E',
			replace: true,
			controller: function() {
				var vm = this;
				vm.alerts = [];

				$rootScope.$on('alert', function(e, alert) {
					vm.alerts.push(alert);
					setTimeout(vm.refresh, 5000);
				});

				vm.refresh = function() {
					vm.alerts.shift();
					$rootScope.$apply();
				}
			},
			controllerAs: 'vm',
			templateUrl: '/directives/ui/alerts.html',
		};
	}])

	.directive('uiPagination', function() {
		return {
			restrict: 'E',
			replace: true,
			bindToController: {
				pagination: '=',
				suffix: '=?'
			},
			controller: function($scope) {
				var vm = this;

				$scope.$watch('pagination.pagination', function(pagination) {
					if(!pagination) return;
					vm.computePages(pagination);
				})

				vm.computePages = function(pagination) {
					vm.pages = [];
					var len = 11;
					var page = pagination.page;
					var start = page - Math.floor(len / 2);
					var end = page + Math.floor(len / 2);

					if(start < 1) {
						end = Math.min(pagination.max, end + Math.abs(start) + 1)
						start = 1
					} else if(end > pagination.max) {
						start = Math.max(1, start - Math.abs(end - pagination.max))
						end = pagination.max;
					}

					for(var i = start; i <= end; i++) {
						vm.pages.push(i);
					}
				}

				vm.changePage = function(page, limit) {
					if(page <= 0 || page > vm.pagination.max) return;
					var suffix = vm.suffix ? vm.suffix : '';
					$scope.$emit('change-page' + suffix, page, limit);
				}
			},
			controllerAs: 'pagination',
			templateUrl: 'directives/pagination.html'
		};
	})

	.directive('footer', function() {
		return {
			scope: {},
			templateUrl: '/directives/ui/footer.html',
			restrict: 'E',
			replace: true
		};
	})
})();
