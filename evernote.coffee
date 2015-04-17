developerToken = process.env.DeveloperToken
Evernote = require('evernote').Evernote
client = new Evernote.Client({token: developerToken})

noteStore = client.getNoteStore('https://app.yinxiang.com/shard/s5/notestore')

module.exports = noteStore