require 'susy'

http_path = "/"
css_dir = "stylesheets"
sass_dir = "sass"
images_dir = "images"
javascripts_dir = "javascripts"

output_style = (environment == :production) ? :compressed : :expanded

preferred_syntax = :sass
