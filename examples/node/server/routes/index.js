var express = require('express');
var router = express.Router();
var path = require('path');

var apidefault = require('../api/default');
var auth = require('../auth');

module.exports = function (app) {
    app.use('/', apidefault);
    app.use('/auth', auth);

    app.use(express.static(path.join(__dirname, '../../dist')));

    app.route('/*').get(function(req, res, next) {
        res.sendFile(path.join(__dirname, '../../dist/index.html'));
    });
}
