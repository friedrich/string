require "susy"

http_path = "/"
css_dir = "build/styles"
sass_dir = "source/styles"
images_dir = "assets"
javascripts_dir = "build/js"

output_style = (environment == :production) ? :compressed : :expanded

preferred_syntax = :sass
