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


### 移动图片 ###
mvFile = (file, target) ->
  cmdStr = "cp -a #{file} #{target}"
  exec cmdStr, (err, stdout, stderr) ->
    if err
      return console.log(err)

    console.log stdout, stderr


shell = (limit=200, f, noteTitle) ->
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

    copFile:['filter', (cb, result) ->
      filter = result.filter
      console.log filter
      for k, v of filter
        for i in v
          if not fs.existsSync k
            fs.mkdirSync k

          mvFile(i, k)


      console.log "copy imgs ok"
    ]



isNumber = (num) ->
  res = Number(num)
  if isNaN(res)
    return false

  return true

console.log argv
f = argv.f
l = 200
t = argv.t

if argv.l
  if isNumber(argv.l) and 0 < argv.l <= 200
    l = argv.l
    shell(l, f, t)
  else
    console.log "l 为笔记大小限制，默认为高级账户最大值:200M。请输入正确的l参数，如：-l 200"

else
  shell(l, f, t)






