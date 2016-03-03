'use strict';

var express  = require('express');
var passport = require('passport');
var auth     = require('./auth.service');
var path     = require("path");
var local = require('./local');

var router = express.Router();

local.setup()

// router.post('/', (req, res) => {
// 	console.log(req.body);
// 	console.log(req.params);
// 	res.send("hello");
// });

router.post('/',
	passport.authenticate('local'),
	function(req, res) {
	    // If this function gets called, authentication was successful.
	    console.log("authenticated: %s, sending token", req.user);

        var token = auth.jwtSign(req.user);

        res.json({'token':token});
	}
);

module.exports = router;
