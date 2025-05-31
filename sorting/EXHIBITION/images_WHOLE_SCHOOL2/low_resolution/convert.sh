#!/bin/bash

# This script recursively finds all .tif, .heic, and .jpeg images (both in IMG folders and elsewhere)  
# and converts them to .jpg format with 95% quality, then removes the original files

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "Error: ImageMagick is not installed. Please install it first."
    exit 1
fi

# Check if HEIF tools are installed (needed for .heic conversion)
if ! command -v heif-convert &> /dev/null; then
    echo "Warning: heif-convert not found. HEIC files will be skipped."
    echo "Install libheif-examples package for HEIC support."
    HEIC_SUPPORT=false
else
    HEIC_SUPPORT=true
fi

# Function to convert file size to KB
get_filesize_kb() {
    du -k "$1" | cut -f1
}

# Function to process TIF files
process_tif_files() {
    local search_path="$1"
    local files=$(find "$search_path" -type f \( -name "*.tif" -o -name "*.TIF" -o -name "*.tiff" -o -name "*.TIFF" \))
    local count=$(echo "$files" | grep -v "^$" | wc -l)
    
    echo "  Found $count TIF images to convert in $search_path"
    
    # Process each .tif image
    local img_index=1
    echo "$files" | grep -v "^$" | while read img; do
        # Skip if empty
        [ -z "$img" ] && continue
        
        # Get original filesize in KB and MB for reporting
        original_size_kb=$(get_filesize_kb "$img")
        original_size_mb=$(echo "scale=2; $original_size_kb/1024" | bc)
        
        echo "  [$img_index/$count] Converting TIF: $img (Original: ${original_size_mb}MB)"
        
        # Create the output jpg filename with _c suffix
        jpg_file="${img%.*}_c.jpg"
        
        # Convert TIF to JPG with 95% quality
        convert "$img" -quality 95 "$jpg_file"
        
        # Check if conversion was successful
        if [ -f "$jpg_file" ]; then
            # Report new size
            new_size_kb=$(get_filesize_kb "$jpg_file")
            new_size_mb=$(echo "scale=2; $new_size_kb/1024" | bc)
            
            echo "    Converted: $(basename "$jpg_file") (Size: ${new_size_mb}MB, ${new_size_kb}KB)"
            
            # Remove the original TIF file
            rm "$img"
            echo "    Removed original TIF file: $(basename "$img")"
        else
            echo "    ERROR: Conversion failed for $(basename "$img")"
        fi
        
        img_index=$((img_index+1))
    done
}

# Function to process JPEG files
process_jpeg_files() {
    local search_path="$1"
    local files=$(find "$search_path" -type f \( -name "*.jpeg" -o -name "*.JPEG" \))
    local count=$(echo "$files" | grep -v "^$" | wc -l)
    
    echo "  Found $count JPEG images to convert in $search_path"
    
    # Process each .jpeg image
    local img_index=1
    echo "$files" | grep -v "^$" | while read img; do
        # Skip if empty
        [ -z "$img" ] && continue
        
        # Get original filesize in KB and MB for reporting
        original_size_kb=$(get_filesize_kb "$img")
        original_size_mb=$(echo "scale=2; $original_size_kb/1024" | bc)
        
        echo "  [$img_index/$count] Converting JPEG: $img (Original: ${original_size_mb}MB)"
        
        # Create the output jpg filename with _c suffix
        jpg_file="${img%.*}_c.jpg"
        
        # Convert JPEG to JPG with 95% quality
        convert "$img" -quality 95 "$jpg_file"
        
        # Check if conversion was successful
        if [ -f "$jpg_file" ]; then
            # Report new size
            new_size_kb=$(get_filesize_kb "$jpg_file")
            new_size_mb=$(echo "scale=2; $new_size_kb/1024" | bc)
            
            echo "    Converted: $(basename "$jpg_file") (Size: ${new_size_mb}MB, ${new_size_kb}KB)"
            
            # Remove the original JPEG file
            rm "$img"
            echo "    Removed original JPEG file: $(basename "$img")"
        else
            echo "    ERROR: Conversion failed for $(basename "$img")"
        fi
        
        img_index=$((img_index+1))
    done
}

# Function to process HEIC files
process_heic_files() {
    local search_path="$1"
    
    if [ "$HEIC_SUPPORT" = true ]; then
        local files=$(find "$search_path" -type f \( -name "*.heic" -o -name "*.HEIC" \))
        local count=$(echo "$files" | grep -v "^$" | wc -l)
        
        echo "  Found $count HEIC images to convert in $search_path"
        
        # Process each .heic image
        local img_index=1
        echo "$files" | grep -v "^$" | while read img; do
            # Skip if empty
            [ -z "$img" ] && continue
            
            # Get original filesize in KB and MB for reporting
            original_size_kb=$(get_filesize_kb "$img")
            original_size_mb=$(echo "scale=2; $original_size_kb/1024" | bc)
            
            echo "  [$img_index/$count] Converting HEIC: $img (Original: ${original_size_mb}MB)"
            
            # Create the output jpg filename with _c suffix
            jpg_file="${img%.*}_c.jpg"
            
            # Convert HEIC to JPG with heif-convert
            heif-convert -q 95 "$img" "$jpg_file"
            
            # Check if conversion was successful
            if [ -f "$jpg_file" ]; then
                # Report new size
                new_size_kb=$(get_filesize_kb "$jpg_file")
                new_size_mb=$(echo "scale=2; $new_size_kb/1024" | bc)
                
                echo "    Converted: $(basename "$jpg_file") (Size: ${new_size_mb}MB, ${new_size_kb}KB)"
                
                # Remove the original HEIC file
                rm "$img"
                echo "    Removed original HEIC file: $(basename "$img")"
            else
                echo "    ERROR: Conversion failed for $(basename "$img")"
            fi
            
            img_index=$((img_index+1))
        done
    else
        echo "  Skipping HEIC conversion as heif-convert is not installed"
    fi
}

# First, find and process all files in the current directory (non-recursive)
echo "Processing files in current directory..."
process_tif_files "."
process_jpeg_files "."
process_heic_files "."

# Then, find and process all IMG directories
echo "Searching for IMG directories..."
img_dirs=$(find . -type d -name "IMG")
dir_count=$(echo "$img_dirs" | grep -v "^$" | wc -l)

echo "Found $dir_count IMG directories"

# Process each IMG directory
dir_index=1
echo "$img_dirs" | grep -v "^$" | while read dir; do
    echo "[$dir_index/$dir_count] Processing directory: $dir"
    
    # Process files in this directory
    process_tif_files "$dir"
    process_jpeg_files "$dir"
    process_heic_files "$dir"
    
    dir_index=$((dir_index+1))
done

# Finally, do a recursive search to find any other files that might be in other directories
echo "Checking for any remaining files in other directories..."
process_tif_files "."
process_jpeg_files "."
process_heic_files "."

echo "All done! Converted all .tif, .jpeg, and .heic files to .jpg format with 95% quality."
