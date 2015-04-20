nodemailer = require('nodemailer')
transport = nodemailer.createTransport
  service: 'QQex'
  auth:
    user: process.env.EMAIL_NAME
    pass: process.env.EMAIL_PWD

module.exports = transport

