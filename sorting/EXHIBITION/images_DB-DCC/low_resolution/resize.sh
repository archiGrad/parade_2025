#!/bin/bash

# This script recursively finds all IMG folders and resizes images within them
# to 256x256 pixels while ensuring they are under 0.5MB in size

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is not installed. Please install it first."
    exit 1
fi

# Function to convert file size to KB
get_filesize_kb() {
    du -k "$1" | cut -f1
}

# Find all IMG directories
echo "Searching for IMG directories..."
img_dirs=$(find . -type d -name "IMG")
dir_count=$(echo "$img_dirs" | wc -l)

echo "Found $dir_count IMG directories"

# Process each IMG directory
dir_index=1
for dir in $img_dirs; do
    echo "[$dir_index/$dir_count] Processing directory: $dir"
    
    # Count images in this directory
    image_count=$(find "$dir" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.JPG" -o -name "*.JPEG" -o -name "*.PNG" -o -name "*.tif" -o -name "*.TIF" \) | wc -l)
    echo "  Found $image_count images to process"
    
    # Process each image in this directory
    img_index=1
    find "$dir" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.JPG" -o -name "*.JPEG" -o -name "*.PNG" -o -name "*.tif" -o -name "*.TIF" \) | while read img; do
        # Get original filesize in KB and MB for reporting
        original_size_kb=$(get_filesize_kb "$img")
        original_size_mb=$(echo "scale=2; $original_size_kb/1024" | bc)
        
        echo "  [$img_index/$image_count] Processing: $(basename "$img") (Original: ${original_size_mb}MB)"
        
        # Set initial quality based on file size
        if [ "$original_size_kb" -gt 10000 ]; then
            # Very large files (>10MB) start with very low quality
            quality=25
        elif [ "$original_size_kb" -gt 5000 ]; then
            # Large files (>5MB) start with low quality
            quality=35
        else
            # Other files start with moderate quality
            quality=50
        fi
        
        # Create a temporary file with unique name
        temp_file="${img}.temp"
        
        # First attempt: resize with initial quality
        convert "$img" -resize 256x256! -quality $quality -strip "$temp_file"
        
        # Check file size
        filesize_kb=$(get_filesize_kb "$temp_file")
        
        # If file is still too large, try more aggressive methods
        attempt=1
        max_attempts=5
        
        while [ "$filesize_kb" -gt 500 ] && [ "$attempt" -lt "$max_attempts" ]; do
            attempt=$((attempt+1))
            
            # Reduce quality further with each attempt
            quality=$((quality-10))
            if [ "$quality" -lt 10 ]; then
                quality=10  # Don't go below 10% quality
            fi
            
            echo "    Attempt $attempt: File still too large ($(echo "scale=2; $filesize_kb/1024" | bc)MB), reducing quality to $quality%"
            
            # Try more aggressive compression
            if [ "$attempt" -eq 2 ]; then
                # Second attempt: add dithering reduction
                convert "$img" -resize 256x256! -quality $quality -strip -dither None "$temp_file"
            elif [ "$attempt" -eq 3 ]; then
                # Third attempt: convert to grayscale if still too large
                convert "$img" -resize 256x256! -quality $quality -strip -dither None -colorspace Gray "$temp_file"
            elif [ "$attempt" -eq 4 ]; then
                # Fourth attempt: reduce colors
                convert "$img" -resize 256x256! -quality $quality -strip -dither None -colors 64 "$temp_file"
            elif [ "$attempt" -eq 5 ]; then
                # Final attempt: use JPEG format which usually compresses better
                # Change extension to .jpg in the filename if it's not already
                if [[ "$img" != *".jpg" && "$img" != *".jpeg" && "$img" != *".JPG" && "$img" != *".JPEG" ]]; then
                    new_img="${img%.*}.jpg"
                    convert "$img" -resize 256x256! -quality 15 -strip -dither None -colors 32 "$temp_file"
                    img="$new_img"
                else
                    convert "$img" -resize 256x256! -quality 15 -strip -dither None -colors 32 "$temp_file"
                fi
            fi
            
            filesize_kb=$(get_filesize_kb "$temp_file")
        done
        
        # Move the temp file to replace the original
        mv "$temp_file" "$img"
        
        # Report new size
        new_size_kb=$(get_filesize_kb "$img")
        new_size_mb=$(echo "scale=2; $new_size_kb/1024" | bc)
        
        echo "    Resized: $(basename "$img") (New: ${new_size_mb}MB, ${new_size_kb}KB)"
        
        if [ "$new_size_kb" -gt 500 ]; then
            echo "    WARNING: Could not reduce file size below 0.5MB threshold!"
        else
            echo "    SUCCESS: File is now under 0.5MB"
        fi
        
        img_index=$((img_index+1))
    done
    
    dir_index=$((dir_index+1))
done

echo "All done! Resized all images in IMG directories to 256x256 pixels."
