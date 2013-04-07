"use strict"

path = require("path")
livereloadSnippet = require("grunt-contrib-livereload/lib/utils").livereloadSnippet

folderMount = (connect, point) ->
	return connect.static(path.resolve(point))

module.exports = (grunt) ->
	grunt.loadNpmTasks("grunt-contrib-clean")
	grunt.loadNpmTasks("grunt-contrib-coffee")
	grunt.loadNpmTasks("grunt-contrib-compass")
	grunt.loadNpmTasks("grunt-symbolic-link");
	grunt.loadNpmTasks("grunt-haml")
	grunt.loadNpmTasks("grunt-contrib-concat")
	grunt.loadNpmTasks("grunt-contrib-connect")
	grunt.loadNpmTasks("grunt-contrib-livereload")
	grunt.loadNpmTasks("grunt-regarde")
	# grunt.loadNpmTasks("grunt-contrib-uglify")

	grunt.initConfig
		pkg: grunt.file.readJSON("package.json")

		clean: ["build"]

		compass:
			all:
				options:
					config: "config.rb"

		coffee:
			all:
				files: grunt.file.expandMapping(["source/**/*.coffee"], "", {
					rename: (base, path) ->
						path.replace(/^source\//, "build/").replace(/\.coffee$/, ".js")
				})

		haml:
			all:
				files: grunt.file.expandMapping(["source/**/*.haml"], "", {
					rename: (base, path) ->
						path.replace(/^source\//, "build/").replace(/\.haml$/, ".html")
				})

		concat:
			js:
				files:
					"build/js/index.js": [
						"source/js/vendor/jquery.js",
						"source/js/vendor/three.js",
						"source/js/vendor/modernizr.three.js",
						"build/js/string.js"
					]

		symlink:
			assets:
				target: "../assets"
				link: "build/assets"
				options:
					force: true
					overwrite: true

		connect:
			all:
				options:
					base: "build"
					port: 8000
					middleware: (connect, options) ->
						[livereloadSnippet, folderMount(connect, options.base)]

		livereload: { }

		regarde:
			coffee:
				files: ["source/js/**/*.coffee"]
				tasks: ["coffee", "concat:js"]
				spawn: true
			sass:
				files: ["source/styles/**/*.sass"]
				tasks: ["compass"]
				spawn: true
			haml:
				files: ["source/**/*.haml"]
				tasks: ["haml"]
				spawn: true
			livereload:
				files: ["assets/**", "build/**"]
				tasks: ["livereload"]

	grunt.registerTask("build", ["haml", "compass", "coffee", "concat", "symlink"])
	grunt.registerTask("default", ["clean", "build"])
	grunt.registerTask("server", ["clean", "build", "livereload-start", "connect", "regarde"])
