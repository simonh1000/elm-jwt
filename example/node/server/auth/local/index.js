'use strict'

var passport      = require('passport'),
	LocalStrategy = require('passport-local').Strategy,
	auth          = require('../auth.service');

exports.setup = function() {
	console.log("setting up local auth");

	passport.use(new LocalStrategy(function(username, password, done) {
		console.log(username, password, username == "testuser" && password == "testpassword");

		if (username == "testuser" && password == "testpassword") {
			console.log("auth success");
			return done(null, {
				username: username,
				id: "123456"
			});
		} else {
			return done(null, false, { message: 'Auth failed.' });
		}
	}));

	passport.serializeUser(function(user, done) {
		// console.log("serialize", user);
		done(null, user.username);
	});

	passport.deserializeUser(function(user, done) {
		done(null, user);
	});
};
