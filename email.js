// Generated by CoffeeScript 1.8.0
(function() {
  var nodemailer, transport;

  nodemailer = require('nodemailer');

  transport = nodemailer.createTransport({
    service: 'QQex',
    auth: {
      user: process.env.EMAIL_NAME,
      pass: process.env.EMAIL_PWD
    }
  });

  module.exports = transport;

}).call(this);

//# sourceMappingURL=email.js.map
