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
		.module('users', [])

		/* Router */

		.config(function ($stateProvider, $locationProvider) {
			$locationProvider.html5Mode(true);
			$stateProvider
				.state({
					name: 'root.settings',
					url: '/settings',
					resolve: {
						email: function(Users, $q) {
							var d = $q.defer();
							Users.getEmail(d.resolve, function () { d.resolve() });
							return d.promise;
						}
					},
					controller: 'SettingsCtrl',
					controllerAs: 'vm',
					templateUrl: '/views/settings.html'
				})
		})

		/* Model */

		.factory('Users', function($http) {
			return {
				getEmail: function(cb, cbErr) {
					$http.get('/api/user/email')
						.success(cb)
						.error(cbErr);
				},
				resendEmail: function(cb, cbErr) {
					$http.put('/api/user/email')
						.success(cb)
						.error(cbErr);
				},
				changeEmail: function(data, cb, cbErr) {
					$http.post('/api/user/email', data)
						.success(cb)
						.error(cbErr);
				},
				changePassword: function(data, cb, cbErr) {
					$http.post('/api/user/password', data)
						.success(cb)
						.error(cbErr);
				},
				changeAlerts: function(data, cb, cbErr) {
					$http.post('/api/user/alerts', data)
						.success(cb)
						.error(cbErr);
				}
			}
		})

		/* Controllers */

		.controller('SettingsCtrl', function(Users, session, email, $scope, $state) {
			if(!session) {
				var r = window.location.href;
				$state.go('root.auth.signin', { redirect: r }, { location: false });
				return;
			}

			var vm = this;
			vm.session = session;
			vm.emailForm = email;
			vm.pwdForm = {};

			this.submitEmail = function() {
				Users.changeEmail(vm.emailForm,
					function(data) {
						vm.emailErrors = null;
						vm.emailForm = data;
						vm.emailForm.sent = true;
						$scope.$emit('alert', {
							status: 'success',
							message: 'Email updated, email verification sent'}
						)
					}, function(err) {
						vm.emailErrors = err.errors;
						vm.emailForm.sent = false;
					});
			}

			this.resendEmailValidation = function() {
				Users.resendEmail(
					function(data) {
						$scope.$emit('alert', {
							status: 'success',
							message: 'Email verification sent'}
						)
					}, function(err) {
						vm.emailErrors = err.errors;
					});
			}

			this.submitPassword = function() {
				Users.changePassword(vm.pwdForm,
					function(data) {
						vm.pwdErrors = null;
						vm.pwdForm = {};
						vm.pwdForm.sent = true;
						$scope.$emit('alert', {
							status: 'success',
							message: 'Password updated'}
						)
					}, function(err) {
						if(err.status == 403) {
							vm.pwdErrors = { old: [err.message] };
						} else {
							vm.pwdErrors = err.errors;
						}
						vm.pwdForm.sent = false;
					});
			}

			this.submitAlerts = function() {
				Users.changeAlerts(vm.session,
					function(data) {
						$scope.$emit('alert', {
							status: 'success',
							message: 'Alerts updated'}
						)
					}, function(err) {});
			}
		})

		/* Directives */

		.directive('userMenu', function() {
			return {
				scope: {},
				bindToController: {
					session: '=?'
				},
				controller: function() {},
				controllerAs: 'vm',
				templateUrl: '/directives/users/menu.html',
				restrict: 'E',
				replace: true
			};
		})
})();
