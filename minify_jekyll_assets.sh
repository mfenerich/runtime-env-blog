#!/bin/bash

# Minify all JavaScript files in the assets/js/ folder
for file in assets/js/*.js; do
  terser "$file" -o "${file%.js}.min.js"
done

# Minify all CSS files in the assets/css/ folder
for file in assets/css/*.css; do
  cssnano "$file" "${file%.css}.min.css"
done
