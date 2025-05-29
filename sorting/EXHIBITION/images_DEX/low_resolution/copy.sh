#!/bin/bash

# Script to copy all image files and PDFs from subdirectories to root directory
# Usage: ./copy_to_root.sh [source_directory]

# Default to current directory if none specified
SOURCE_DIR="${1:-.}"
TARGET_DIR="."

# Image file extensions to search for (case sensitive)
IMAGE_EXTENSIONS="jpg|JPG|jpeg|JPEG|png|PNG|heic|HEIC|tif|TIF|tiff|TIFF|gif|GIF|bmp|BMP|webp|WEBP"

echo "Copying image files from subdirectories to root directory..."

# Find and copy image files (ignoring files already in the root directory)
find "$SOURCE_DIR" -mindepth 2 -type f -regextype posix-extended -regex ".*\.(${IMAGE_EXTENSIONS})$" -size +1c -exec cp -v {} "$TARGET_DIR" \;

echo "Copying PDF files from subdirectories to root directory..."

# Find and copy PDF files (ignoring files already in the root directory)
find "$SOURCE_DIR" -mindepth 2 -type f -regextype posix-extended -regex ".*\.(pdf|PDF)$" -size +1c -exec cp -v {} "$TARGET_DIR" \;

echo "Copy operation completed."

# Count files copied to root
image_count=$(find "$TARGET_DIR" -maxdepth 1 -type f -regextype posix-extended -regex ".*\.(${IMAGE_EXTENSIONS})$" -size +1c | wc -l)
pdf_count=$(find "$TARGET_DIR" -maxdepth 1 -type f -regextype posix-extended -regex ".*\.(pdf|PDF)$" -size +1c | wc -l)

echo "Root directory now has $image_count image files and $pdf_count PDF files."
