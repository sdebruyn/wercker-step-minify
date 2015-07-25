# Minify step for wercker
This [wercker](http://wercker.com) step minifies static resources like HTML, CSS and JS files.

[![wercker status](https://app.wercker.com/status/777b41e2e1d76a0ef8b13d56da4bdcbb/m "wercker status")](https://app.wercker.com/project/bykey/777b41e2e1d76a0ef8b13d56da4bdcbb)

This step is designed to be used with a static site generator like [Jekyll](http://jekyllrb.com) or [hugo](http://gohugo.io). You can configure it to fit your needs.

## Configuration

All parameters are optional. Don't put them in your *wercker.yml* to use the default values.

* `basedir`: The directory containing the website to be minified. *Default is `public`*
* `threads`: The number of simultaneous operations. Put this between quotes (e.g. *"4"*). *Default is the number of cores of the host.*
* `htmlargs`: The arguments for [html-minifier](https://github.com/kangax/html-minifier). *Default is `--use-short-doctype --remove-style-link-type-attributes --remove-script-type-attributes --remove-comments --minify-css --minify-js --collapse-whitespace --remove-comments-from-cdata --conservative-collapse --remove-cdatasections-from-cdata`.*
* `yuiargs`: The arguments for [yui-compressor](https://github.com/yui/yuicompressor). *No arguments by default.*

### New Wercker (*ewok*) infrastructure example (with Docker)

	box: debian
	build:
	  steps:
	    - samueldebruyn/minify:
	        basedir: _site
	        threads: "3"
			htmlargs: --remove-style-link-type-attributes --remove-script-type-attributes --remove-comments

### Old Wercker infrastructure example

	box: wercker/default
	build:
	  steps:
	    - samueldebruyn/minify:
	        basedir: _site
	        threads: "3"
			htmlargs: --remove-style-link-type-attributes --remove-script-type-attributes --remove-comments

## How it works

This script uses [html-minifier](https://github.com/kangax/html-minifier) to minify HTML files and [yui-compressor](https://github.com/yui/yuicompressor) to minify CSS and JS files. This also means that the script installs node and java if they aren't already installed.

The script should work on any OS using *apt-get* or *yum*.

## Contributing and license

This wercker step is licensed under the MIT License. Create a pull request or an issue to contribute.