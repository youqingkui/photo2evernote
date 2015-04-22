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
exec = require('child_process').exec

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



gimgFiles = []
### 筛选图片 ###
filterImg = (dir=process.cwd(), limit=100, forDir=false) ->
  files = fs.readdirSync dir

  for f in files
    file = dir + '/' + f
    type = mime.lookup(file)
    if type of MIME_TO_EXTESION_MAPPING and fs.statSync(file).size < 1024 * 1024 * limit
      gimgFiles.push file
    else if fs.statSync(file).isDirectory() and forDir
      tmp =  dir + '/' + f
      console.log tmp
      filterImg(tmp, limit, forDir)



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
creatImportNote = (filter, noteTitle, cb) ->
  scptHead = 'tell application "Evernote"\n'
  scptPwdArr = pwd[1..]
  scptPwd = '"Macintosh HD:'
  for i in scptPwdArr
    scptPwd += i + ":"

  for k, v of filter
    tmp = []
    if noteTitle
      ENEM = createENEM_HEAD(noteTitle + ' ' + k)
    else
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
    scptHead += "\timport #{scptPwd + k}.enex" + '" to "01-目录"\n'

  scptHead += 'end tell'
  importScpt = fs.createWriteStream 'import.scpt'
  importScpt.write scptHead
  console.log "import enex all do"
  console.log scptHead
  cb()





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






shell = (limit=100, f, noteTitle) ->
  console.log "limit", limit
  async.auto
    getImg:(cb) ->
      filterImg process.cwd(), limit, f
      cb(null, gimgFiles)


    filter:['getImg', (cb, result) ->
      imgs = result.getImg
      sliceImg imgs, limit, (filter) ->
        console.log filter
        cb(null, filter)
    ]
#
#    copFile:['filter', (cb, result) ->
#      filter = result.filter
#      console.log filter
#      for k, v of filter
#        for i in v
#          if fs.existsSync k
#            fse.copySync i, k + '/' +  i
#          else
#            fs.mkdirSync k
#            fse.copySync i, k + '/' + i
#
#      console.log "copy imgs ok"
#    ]
#
    cImportNote:['filter', (cb, result) ->
      filter = result.filter
      creatImportNote(filter, noteTitle,  cb)
    ]
#
#    doScript:['cImportNote', (cb) ->
#      exec "osascript import.scpt", (err, stdout, stderr) ->
#        return console.log err if err
#
#        console.log stdout
#        console.log stderr
#        console.log "scpt"
#    ]


console.log argv
f = argv.f
l = 100
t = argv.t
if argv.l
  l = argv.l
shell(l, f, t)



