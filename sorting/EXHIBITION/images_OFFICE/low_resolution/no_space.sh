#!/bin/bash

# This script recursively finds files with spaces in their filenames
# and replaces those spaces with underscores

# Function to replace spaces in filenames with underscores
replace_spaces() {
    local file="$1"
    local dir=$(dirname "$file")
    local base=$(basename "$file")
    
    # Create the new filename by replacing spaces with underscores
    local new_base=$(echo "$base" | tr " " "_")
    
    # Skip if filename doesn't need changes
    if [ "$base" = "$new_base" ]; then
        return 0
    fi
    
    local new_file="${dir}/${new_base}"
    
    echo "  Renaming: ${base}"
    echo "        to: ${new_base}"
    
    # Rename the file
    mv "$file" "$new_file"
    
    # Return success if rename was successful
    if [ $? -eq 0 ]; then
        return 0
    else
        echo "    ERROR: Failed to rename file: ${base}"
        return 1
    fi
}

# Function to process files in a directory
process_directory() {
    local search_path="$1"
    local files=$(find "$search_path" -type f)
    local count=$(echo "$files" | grep -v "^$" | wc -l)
    
    echo "  Found $count files to check in $search_path"
    
    # Process each file
    local file_index=1
    local renamed=0
    echo "$files" | grep -v "^$" | while read file; do
        # Skip if empty
        [ -z "$file" ] && continue
        
        echo "  [$file_index/$count] Checking: $file"
        
        # Check if filename contains spaces using direct comparison
        base=$(basename "$file")
        new_base=$(echo "$base" | tr " " "_")
        if [ "$base" != "$new_base" ]; then
            replace_spaces "$file"
            if [ $? -eq 0 ]; then
                renamed=$((renamed+1))
            fi
        else
            echo "    No spaces to replace"
        fi
        
        file_index=$((file_index+1))
    done
    
    echo "  Renamed $renamed files in $search_path"
}

# First, process files in the current directory (non-recursive)
echo "Processing files in current directory..."
process_directory "."

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
    process_directory "$dir"
    
    dir_index=$((dir_index+1))
done

# Finally, do a recursive search to find any other files in other directories
echo "Checking for any remaining files with spaces in other directories..."
process_directory "."

echo "All done! Replaced spaces with underscores in all filenames."
