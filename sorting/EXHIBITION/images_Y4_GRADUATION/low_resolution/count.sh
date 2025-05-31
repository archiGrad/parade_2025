#!/bin/bash

# Script to count image files larger than 1 byte recursively (max 2 levels deep)
# Usage: ./count_images.sh [directory]

# Default to current directory if none specified
SEARCH_DIR="${1:-.}"

# Image file extensions to search for (case sensitive)
IMAGE_EXTENSIONS="jpg|JPG|jpeg|JPEG|png|PNG|heic|HEIC|tif|TIF|tiff|TIFF|gif|GIF|bmp|BMP|webp|WEBP"

# Find and count image files
image_count=$(find "$SEARCH_DIR" -maxdepth 4 -type f -regextype posix-extended -regex ".*\.(${IMAGE_EXTENSIONS})$" -size +1c | wc -l)

echo "Found $image_count image files (larger than 1 byte) in $SEARCH_DIR (max 2 levels deep)"

# Optionally list the files (uncomment to enable)
# echo "List of image files:"
# find "$SEARCH_DIR" -maxdepth 2 -type f -regextype posix-extended -regex ".*\.(${IMAGE_EXTENSIONS})$" -size +1c
