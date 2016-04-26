'use strict';

var jwt = require("jsonwebtoken");

var jwtSecret = "elm jwt";

var jwtSign = function (user) {
    var options = { expiresIn: "1h" };
    console.log("jwtSign", user);
    return jwt.sign(user, jwtSecret, options);
};

var ensureAuthorized = function (req, res, next) {
    var bearerHeader = req.headers["authorization"];
    if (typeof bearerHeader == 'undefined')
        return res.status(401).send('Server response: no auth credential found');

    var bearertoken = bearerHeader.split(' ');
    var token = bearertoken[1];

    return jwt.verify(token, jwtSecret, function (err, user) {
        if (err) {
            if (err.name == 'TokenExpiredError') {
                console.log("ensureAuthorized: auth error: ", err);
                return res.status(401).send('TokenExpiredError');
            }
            console.log("ensureAuthorized: JsonWebTokenError: ", err.message);
            return res.status(401).send('JsonWebTokenError');
        }
        req.user = user;
        return next();
    });
};

// var ensureAdmin = function (req, res, next) {
//     ensureAuthorized(req, res, function () {
//         if (req.user.role == 'admin')
//             return next();
//         else {
//             console.log("ensureAdmin: failed");
//             res.sendStatus(403);
//         }
//     });
// };

exports.ensureAuthorized = ensureAuthorized;
exports.jwtSign = jwtSign;
// exports.ensureAdmin = ensureAdmin;
