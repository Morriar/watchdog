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
		.module('auth', [])

		/* Router */

		.config(function ($stateProvider, $locationProvider) {
			$locationProvider.html5Mode(true);
			$stateProvider
				.state({
					name: 'root.auth',
					url: '/auth',
					controller: function() {},
					controllerAs: 'vm',
					templateUrl: '/views/auth/auth.html',
					abstract: true
				})
				.state({
					name: 'root.auth.signup',
					url: '/signup',
					controller: 'SignupCtrl',
					controllerAs: 'vm',
					templateUrl: '/views/auth/signup.html'
				})
				.state({
					name: 'root.auth.signin',
					url: '/login',
					controller: 'SigninCtrl',
					controllerAs: 'vm',
					templateUrl: '/views/auth/signin.html'
				})
				.state({
					name: 'root.auth.signout',
					url: '/signout',
					controller: 'SignoutCtrl',
					controllerAs: 'vm',
					templateUrl: '/views/auth/signout.html'
				})
				.state({
					name: 'root.auth.out',
					url: '/out',
					templateUrl: '/views/auth/signout.html'
				})
				.state({
					name: 'root.auth.lostpassword',
					url: '/lost_password',
					controller: 'LostPasswordCtrl',
					controllerAs: 'vm',
					templateUrl: '/views/auth/lostpassword.html'
				})
				.state({
					name: 'root.auth.resetpassword',
					url: '/reset_password',
					controller: 'ResetPasswordCtrl',
					controllerAs: 'vm',
					templateUrl: '/views/auth/resetpassword.html'
				})
				.state({
					name: 'root.auth.emailactivation',
					url: '/email_activation',
					controller: 'EmailActivationCtrl',
					controllerAs: 'vm',
					templateUrl: '/views/auth/emailactivation.html'
				})
		})

		/* Model */

		.factory('Auth', function(Errors, $http) {
			return {
				auth: function(cb, cbErr) {
					$http.get('/api/auth')
						.success(cb)
						.error(cbErr);
				},
				signin: function(data, cb, cbErr) {
					$http.post('/api/auth/login', data)
						.success(cb)
						.error(cbErr);
				},
				signup: function(data, cb, cbErr) {
					$http.post('/api/auth/signin', data)
						.success(cb)
						.error(cbErr);
				},
				signout: function(cb, cbErr) {
					$http.get('/api/auth/logout')
						.success(cb)
						.error(cbErr);
				},
				lostPassword: function(data, cb, cbErr) {
					$http.post('/api/auth/password/lost', data)
						.success(cb)
						.error(cbErr);
				},
				resetPassword: function(data, cb, cbErr) {
					$http.post('/api/auth/password/reset', data)
						.success(cb)
						.error(cbErr);
				}
			}
		})

		/* Controllers */

		.controller('SignupCtrl', function(Auth, $state) {
			var vm = this;
			vm.form = {};

			this.submit = function() {
				vm.form.password2 = vm.form.password1;
				Auth.signup(vm.form,
					function(data) {
						window.location.reload();
					}, function(err) {
						vm.errors = err.errors;
					});
			}
		})

		.controller('SigninCtrl', function(Auth) {
			var vm = this;
			vm.form = {};

			this.submit = function() {
				Auth.signin(vm.form,
					function(data) {
						vm.errors = null;
						window.location.reload();
					}, function(err) {
						vm.errors = err.errors;
						if(err.status == 403) {
							vm.errors = { password: ["Bad credentials"] }
						}
					});
			}
		})

		.controller('SignoutCtrl', function(Auth, $state) {
			Auth.signout(function(data) {
				window.location.replace('/');
			}, function(err) {});
		})

		.controller('LostPasswordCtrl', function(Auth) {
			var vm = this;
			vm.form = {};

			this.submit = function() {
				Auth.lostPassword(vm.form,
					function(data) {
						vm.errors = null;
						vm.success = true;
					}, function(err) {
						vm.errors = err.errors;
						if(err.status == 404) {
							vm.errors = { email: ["Unknown email"] }
						}
					});
			}
		})

		.controller('ResetPasswordCtrl', function(Auth, $location) {
			var vm = this;
			vm.form = {
				reset_token: $location.search().token
			};

			this.submit = function() {
				vm.form.password2 = vm.form.password1;
				Auth.resetPassword(vm.form,
					function(data) {
						vm.errors = null;
						vm.success = true;
					}, function(err) {
						vm.errors = err.errors;
						if(err.status == 404) {
							vm.errors = { login: ["Username not found"] }
						}
						if(err.status == 403) {
							vm.errors = { password1: ["Token error"] }
						}
					});
			}
		})

		.controller('EmailActivationCtrl', function(Auth, $location) {
			this.status = $location.search().email_validation;
		})
})();
