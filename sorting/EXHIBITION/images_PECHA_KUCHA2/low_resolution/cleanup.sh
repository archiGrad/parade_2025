#!/bin/bash

# Improved cleanup script for document structure
# 1. Renames folders without IMG/IMAGE and PDF subfolders to {name}_EMPTY
# 2. Keeps only the first PDF in each PDF directory

# Initialize counters
renamed_count=0
deleted_pdf_count=0
total_dir_count=0
already_empty_count=0

echo "Starting cleanup process..."

# First pass: handle renaming directories
for dir in */; do
    # Remove trailing slash
    dirname="${dir%/}"
    total_dir_count=$((total_dir_count + 1))
    
    # Skip directories that are not student folders (like script files)
    if [[ "$dirname" == *.sh || "$dirname" == *.html || "$dirname" == *.json ]]; then
        echo "Skipping non-student directory: $dirname"
        total_dir_count=$((total_dir_count - 1))
        continue
    fi
    
    # Remove _EMPTY suffix if already present (we'll add it back if needed)
    base_dirname="${dirname%_EMPTY}"
    base_dirname="${base_dirname%_*}" # Remove any _1, _2 suffixes
    
    # Check if both IMG/IMAGE and PDF folders exist
    if [[ ! -d "$dirname/IMG" && ! -d "$dirname/IMAGE" ]] || [[ ! -d "$dirname/PDF" ]]; then
        # If it's not already marked as empty
        if [[ "$dirname" != *"_EMPTY" ]]; then
            echo "Marking as empty: $dirname -> ${base_dirname}_EMPTY"
            mv "$dirname" "${base_dirname}_EMPTY"
            renamed_count=$((renamed_count + 1))
            dirname="${base_dirname}_EMPTY"
        else
            echo "Directory already marked as empty: $dirname"
            already_empty_count=$((already_empty_count + 1))
        fi
    elif [[ "$dirname" == *"_EMPTY" ]]; then
        # Has required folders but is marked as EMPTY - remove the mark
        echo "Removing incorrect EMPTY mark: $dirname -> ${base_dirname}"
        mv "$dirname" "${base_dirname}"
        dirname="${base_dirname}"
    else
        echo "Directory has required folders: $dirname"
    fi
    
    # Handle PDF folder cleanup - keep only the first PDF
    if [[ -d "$dirname/PDF" ]]; then
        echo "Processing PDFs in: $dirname/PDF"
        
        # Find all PDFs in the directory
        pdfs=()
        while IFS= read -r -d $'\0' pdf; do
            pdfs+=("$pdf")
        done < <(find "$dirname/PDF" -type f -name "*.pdf" -print0)
        
        # Sort PDF files to ensure consistent results
        IFS=$'\n' sorted_pdfs=($(sort <<<"${pdfs[*]}"))
        unset IFS
        
        # If there's at least one PDF
        if [[ ${#sorted_pdfs[@]} -gt 0 ]]; then
            # Keep the first one
            echo "  Keeping first PDF: $(basename "${sorted_pdfs[0]}")"
            
            # Delete the rest
            for ((i=1; i<${#sorted_pdfs[@]}; i++)); do
                echo "  Removing extra PDF: $(basename "${sorted_pdfs[$i]}")"
                rm "${sorted_pdfs[$i]}"
                deleted_pdf_count=$((deleted_pdf_count + 1))
            done
        fi
    fi
done

# Print summary
echo "===== CLEANUP SUMMARY ====="
echo "Total directories processed: $total_dir_count"
echo "Directories renamed to *_EMPTY: $renamed_count"
echo "Directories already marked as EMPTY: $already_empty_count"
echo "PDF files deleted: $deleted_pdf_count"
echo "Cleanup completed!"
