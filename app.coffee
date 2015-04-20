#!/usr/bin/env node

noteStore = require('./evernote')
Evernote = require('evernote').Evernote
fs = require('fs')
crypto = require('crypto')
mime = require('mime')
async = require('async')
fse = require('fs-extra')
email = require('./email')
argv = require('optimist').argv

MIME_TO_EXTESION_MAPPING = {
  'image/png': '.png',
  'image/jpg': '.jpg',
  'image/jpeg': '.jpg',
  'image/gif': '.gif'
}

pwd = process.cwd().split('/')

createENEM_HEAD = (title) ->
  xml = '<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE en-export SYSTEM "http://xml.evernote.com/pub/evernote-export3.dtd"><en-export export-date="20150420T023922Z" application="Evernote" version="Evernote Mac 6.0.8 (451398)"><note><title>' + title
  xml += '</title><content><![CDATA[<?xml version="1.0" encoding="UTF-8" standalone="no"?><!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml2.dtd"><en-note>'
  return xml

ENEM_END = "</en-note>]]></content><created>#{new Date()}</created><updated>#{new Date()}</updated><note-attributes><latitude>22.60284578376065</latitude><longitude>114.0366381790896</longitude><altitude>87.88452911376953</altitude><author>#{process.env.USER}</author><source>desktop.mac</source><reminder-order>0</reminder-order></note-attributes>"

ENEM_RES_HEAD = '<resource><data encoding="base64">'

createENEM_RES_END = (res) ->
  return "</data><mime>#{res.mime}</mime><width></width><height></height><duration>0</duration><resource-attributes><file-name>#{res.name}</file-name></resource-attributes></resource>"



### 筛选图片 ###
filterImg = (limit=100, cb) ->

  fs.readdir process.cwd(), (err, files) ->
    return cb(err) if err

    imgFiles = []
    for f in files
      type = mime.lookup(f)
      if type of MIME_TO_EXTESION_MAPPING and fs.statSync(f).size < 1024 * 1024 * limit
        imgFiles.push f

    cb(null, imgFiles)

### 按限制大小分组图片 ###
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

### 邮件创建笔记 ###
createEmailNote = (filter) ->
  for k, v of filter
    mailOption = {
      from:'yuankui'
      to:'shasha'
      subject:k
      attachments:[]
    }
    for i in v
      tmp = {}
      tmp.filename = i
      tmp.path = i
      mailOption.attachments.push tmp

    email.sendMail mailOption, (err, info) ->
      return console.log err if err

      console.log info

### 创建导入笔记 ###
creatImportNote = (filter) ->
  for k, v of filter
    tmp = []
    ENEM = createENEM_HEAD(pwd[pwd.length - 1] + ' ' + k)
    for i in v
      readImg i, (res) ->
        tmp.push res

    for t in tmp
      ENEM += '<div><en-media style="height: auto;" type="' + t.mime + '" hash="' + createHashHex(t.image) + '"/></div>'

    ENEM += ENEM_END

    for t in tmp
      ENEM += ENEM_RES_HEAD + t.data.bodyHash + createENEM_RES_END(t)
    ENEM += "</note></en-export>"
    enex = fs.createWriteStream k + '.enex'
    enex.write ENEM

  console.log "all do"





### 生成笔记内容HASH ###
createHashHex = (body) ->
  md5 = crypto.createHash('md5')
  md5.update(body)
  hashHex = md5.digest('hex')
  return hashHex



### 读取图片返回resource ###
readImg = (img, cb) ->
  image = fs.readFileSync(img)
  hash = image.toString('base64')
  data = new Evernote.Data()
  data.size = image.length
  data.bodyHash = hash
  data.body = image

  resource = new Evernote.Resource()
  resource.mime = mime.lookup(img)
  resource.data = data
  resource.name = img
  resource.image = image
  cb(resource)






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
#    emailNote:['filter', (cb, result) ->
#      filter = result.filter
#      createEmailNote filter
#
#    ]
    cImportNote:['filter', (cb, result) ->
      filter = result.filter
      creatImportNote(filter)
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
#    data.bodyHash = "hash"
#    data.body = "image"
#
#    resource = new Evernote.Resource()
#    resource.mime = mime.lookup(item)
#    resource.data = data
#
#    resources.push resource
#
#    callback()
#
#  ,(eachErr) ->
#    return cb(eachErr) if eachErr



