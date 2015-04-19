#!/usr/bin/env node

noteStore = require('./evernote')
Evernote = require('evernote').Evernote
fs = require('fs')
crypto = require('crypto')
mime = require('mime')
async = require('async')
fse = require('fs-extra')
argv = require('optimist').argv

MIME_TO_EXTESION_MAPPING = {
  'image/png': '.png',
  'image/jpg': '.jpg',
  'image/jpeg': '.jpg',
  'image/gif': '.gif'
}



filterImg = (limit=100, cb) ->

  fs.readdir process.cwd(), (err, files) ->
    return cb(err) if err

    imgFiles = []
    for f in files
      type = mime.lookup(f)
      if type of MIME_TO_EXTESION_MAPPING and fs.statSync(f).size < 1024 * 1024 * limit
        imgFiles.push f
    cb(null, imgFiles)


sliceImg = (imgFiles, limit=100, cb) ->
  filter = {}
  index = 1
  count = 0
  for k, v in imgFiles
    if not filter[index]
      filter[index] = []

    count += fs.statSync(k).size
    if count < 1024 * 1024 * limit
      filter[index].push k

    else
      index += 1
      if fs.statSync(k).size < 1024 * 1024 * limit
        filter[index] = []
        filter[index].push k
        count = fs.statSync(k).size


  cb(filter)




shell = (limit=100) ->
  async.auto
    getImg:(cb) ->
      filterImg limit, (err, res) ->
        return console.log err if err
        cb(null, res)


    filter:['getImg', (cb, result) ->
      console.log "limit"
      imgs = result.getImg
      sliceImg imgs, limit, (filter) ->
        cb(null, filter)
    ]

    copFile:['filter', (cb, result) ->
      filter = result.filter
      console.log filter
      for k, v of filter
        for i in v
          if fs.existsSync k
            fse.copySync i, k + '/' +  i
          else
            fs.mkdirSync k
            fse.copySync i, k + '/' + i

      console.log "ok"
    ]


if argv.l
  limit = argv.l
  shell(limit)

else
  shell()

#createRes = (imgFiles, cb) ->
#  resources = []
#  async.eachSeries imgFiles, (item, callback) ->
#    image = fs.readFileSync(item)
#    hash = image.toString('base64')
#    data = new Evernote.Data()
#    data.size = image.length
#    data.bodyHash = hash
#    data.body = image
#
#    resource = new Evernote.Resource()
#    resource.mime = mime.lookup(item)
#    resource.data = data
#
#    resource.push resource
#
#    callback()
#
#  ,(eachErr) ->
#    return cb(eachErr) if eachErr






#createNote = (cb) ->
#  note = new Evernote.Note()
#  note.title = "Test Note"



