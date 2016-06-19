var express = require('express');
var router = express.Router();

var auth = require('../../auth/auth.service');

router.get('/test', auth.ensureAuthorized, index);

function index(req, res) {
    res.send({data: "I only replied because you were authorised!"});
}

module.exports = router;
