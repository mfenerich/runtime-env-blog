#!/bin/bash

# Minify JavaScript files in the assets/js/ folder
for file in assets/js/*.js; do
  # Skip files that already have .min in their name
  if [[ $file != *.min.js ]]; then
    terser "$file" -o "${file%.js}.min.js"
  fi
done

# Minify CSS files in the assets/css/ folder
for file in assets/css/*.css; do
  # Skip files that already have .min in their name
  if [[ $file != *.min.css ]]; then
    cssnano "$file" "${file%.css}.min.css"
  fi
done
