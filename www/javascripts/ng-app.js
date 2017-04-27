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
	angular.module('ng-app', ['ui.router', 'angular-loading-bar', 'sites'])

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
				name: 'home',
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
				name: 'root.otherwise',
				url: '*path',
				template: '<panel404 />'
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

				vm.pages = [];
				var page = 0;
				while(page < vm.pagination.max) {
					page++;
					vm.pages.push(page);
				}

				vm.changePage = function(page, limit) {
					if(page <= 0 || page > vm.pages.length) return;
					var suffix = vm.suffix ? vm.suffix : '';
					$scope.$emit('change-page' + suffix, page, limit);
				}
			},
			controllerAs: 'pagination',
			templateUrl: 'directives/pagination.html'
		};
	})
})();
