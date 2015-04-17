noteStore = require('./evernote')
Evernote = require('evernote').Evernote
fs = require('fs')
crypto = require('crypto')
mime = require('mime')
async = require('async')

MIME_TO_EXTESION_MAPPING = {
  'image/png': '.png',
  'image/jpg': '.jpg',
  'image/jpeg': '.jpg',
  'image/gif': '.gif'
}



getImgs = (cb) ->

  fs.readdir process.cwd(), (err, files) ->
    return cb(err) if err

    imgFiles = []
    for f in files
      type = mime.lookup(f)
      if type of MIME_TO_EXTESION_MAPPING and fs.statSync(f).size < 1024 * 1024 * 10
        imgFiles.push f

    cb(null, imgFiles)


filterImgs = (imgFiles, cb) ->
  filter = {}
  count = 0
  index = 1
  start = 0
  for v, k  in imgFiles
    if fs.statSync(v).size < 1024 * 1024 * 10
      console.log v
      count += fs.statSync(v).size
      if count >= 1024 * 1024 * 10
        console.log k
        filter[index] = imgFiles[start...k]
        index += 1
        count = 0
        start = k

  console.log filter


async.auto
  getImg:(cb) ->
    getImgs (err, res) ->
      return console.log err if err

      cb(null, res)


  filter:['getImg', (cb, result) ->
    imgs = result.getImg
    filterImgs imgs, (cb) ->

  ]





createRes = (imgFiles, cb) ->
  resources = []
  async.eachSeries imgFiles, (item, callback) ->
    image = fs.readFileSync(item)
    hash = image.toString('base64')
    data = new Evernote.Data()
    data.size = image.length
    data.bodyHash = hash
    data.body = image

    resource = new Evernote.Resource()
    resource.mime = mime.lookup(item)
    resource.data = data

    resource.push resource

    callback()

  ,(eachErr) ->
    return cb(eachErr) if eachErr






createNote = (cb) ->
  note = new Evernote.Note()
  note.title = "Test Note"



