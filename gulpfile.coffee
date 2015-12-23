_ = require 'lodash'
browserify = require 'browserify'
buffer = require 'vinyl-buffer'
changed = require 'gulp-changed'
connect = require 'gulp-connect'
coffee = require 'gulp-coffee'
coffeelint = require 'gulp-coffeelint'
gulp = require 'gulp'
gutil = require 'gulp-util'
nib = require 'nib'
plumber = require 'gulp-plumber'
uglify = require 'gulp-uglify'
stylus = require 'gulp-stylus'
source = require 'vinyl-source-stream'
sourcemaps = require 'gulp-sourcemaps'
watchify = require 'watchify'

# build/js/*.js -> dist/js/*.js
browserifyOpts =
  entries: './build/js/app.js'
  debug: true
  bundleExternal: true
  ignoreMissing: true

triggerReload = (stream) -> stream.pipe(connect.reload())

bundle = (bundler, src='app.js') ->
  # bundler is an instance of either browserify or watchify
  bundler.bundle()
    .pipe source(src)
    .pipe buffer()
    .pipe sourcemaps.init({loadMaps: true})
    .pipe uglify()
    .on 'error', gutil.log
    .pipe sourcemaps.write('.')
    .pipe gulp.dest('./dist/js/')

gulp.task 'default', ['dev']

gulp.task 'bundle:dev', ['watch:coffee'], ->
  opts = _.assign {}, watchify.args, browserifyOpts
  b = watchify browserify(opts)
  bundleAndReload = -> triggerReload bundle(b)
  b.on 'update', bundleAndReload
  b.on 'log', gutil.log
  bundleAndReload()

COFFEE_SRC = [
  './src/coffee/**/*.coffee'
  '!./src/coffee/**/__tests__/*.coffee'
]

gulp.task 'watch:coffee', ['js'], ->
  gulp.watch COFFEE_SRC, ['js:dev']
    .on 'change', (evt) ->
      console.log "#{evt.path} #{evt.type}"

gulp.task 'coffeelint', ->
  gulp.src COFFEE_SRC
    .pipe coffeelint()
    .pipe coffeelint.reporter() # log the errors
    .pipe coffeelint.reporter('fail') # end process if there were any lint errors

gulp.task 'js', ['coffeelint'], ->
  gulp.src COFFEE_SRC
    .pipe plumber()
    .pipe sourcemaps.init()
    .pipe coffee()
    .pipe sourcemaps.write()
    .pipe gulp.dest('./build/js')

# src/coffee/*.coffee -> build/js/*.js
gulp.task 'js:dev', ['coffeelint'], ->
  gulp.src COFFEE_SRC
    .pipe plumber()
    .pipe changed('./build/js', {extension: '.js'})
    .pipe sourcemaps.init()
    .pipe coffee()
    .pipe sourcemaps.write()
    .pipe gulp.dest('./build/js')

HTML_SRC = './src/html/**/*.html'

# src/html/*.html -> dist/*.html
html = (opts) ->
  DEST = './dist'
  stream = gulp.src HTML_SRC
  stream = stream.pipe(changed DEST) if opts?.dev
  stream.pipe gulp.dest(DEST)

gulp.task 'html', html

gulp.task 'html:reload', -> triggerReload html {dev: true}

gulp.task 'watch:html', ['html'], ->
  gulp.watch HTML_SRC, ['html:reload']
    .on 'change', (evt) ->
      console.log "#{evt.path} #{evt.type}"

STYL_SRC = './src/styl/**/*.styl'

# src/styl/*.styl -> dist/css/*.css
css = ->
  # compile .styl files to .css and .css.map
  gulp.src STYL_SRC
    .pipe sourcemaps.init()
    .pipe plumber()
    .pipe stylus(
        'include css': true
        'resolve url': true # minifies imported css as a side effect
        use: nib()
        compress: true
      )
    .on 'error', gutil.log
    .pipe sourcemaps.write('.')
    .pipe gulp.dest('./dist/css')

gulp.task 'css', css

gulp.task 'css:reload', -> triggerReload css()

gulp.task 'watch:stylus', ['css'], ->
  gulp.watch STYL_SRC, ['css:reload']
    .on 'change', (evt) ->
      console.log "#{evt.path} #{evt.type}"

gulp.task 'dev', ['bundle:dev', 'watch:stylus', 'watch:html'], ->
  connect.server {
    port: 8000
    root: 'dist'
    livereload: true
  }
