#!/bin/bash

# PDF Compressor for Git Repository
# Compresses PDFs over 30MB and manages .gitignore

TARGET_SIZE_MB=30
BACKUP=true
GITIGNORE_FILE=".gitignore"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to get file size in MB
get_size_mb() {
    local file="$1"
    local size_bytes=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    echo "scale=2; $size_bytes / 1048576" | bc
}

# Function to check if file is in .gitignore
is_in_gitignore() {
    local file="$1"
    grep -Fxq "$file" "$GITIGNORE_FILE" 2>/dev/null
}

# Function to add file to .gitignore
add_to_gitignore() {
    local file="$1"
    if ! is_in_gitignore "$file"; then
        echo "$file" >> "$GITIGNORE_FILE"
        echo -e "${BLUE}Added to .gitignore: $file${NC}"
    fi
}

# Function to remove file from .gitignore
remove_from_gitignore() {
    local file="$1"
    if [ -f "$GITIGNORE_FILE" ] && is_in_gitignore "$file"; then
        # Create temp file without the line
        grep -Fxv "$file" "$GITIGNORE_FILE" > "${GITIGNORE_FILE}.tmp" && mv "${GITIGNORE_FILE}.tmp" "$GITIGNORE_FILE"
        echo -e "${BLUE}Removed from .gitignore: $file${NC}"
    fi
}

# Function to compress PDF using Ghostscript
compress_pdf() {
    local input="$1"
    local output="$2"
    local quality="$3"
    
    case $quality in
        "screen") gs_quality="/screen" ;;
        "ebook") gs_quality="/ebook" ;;
        "printer") gs_quality="/printer" ;;
        *) gs_quality="/ebook" ;;
    esac
    
    gs -sDEVICE=pdfwrite \
       -dCompatibilityLevel=1.4 \
       -dPDFSETTINGS=$gs_quality \
       -dNOPAUSE \
       -dQUIET \
       -dBATCH \
       -sOutputFile="$output" \
       "$input" 2>/dev/null
    
    return $?
}

# Function to process a single PDF
process_pdf() {
    local file="$1"
    local original_size=$(get_size_mb "$file")
    
    echo -e "\n${BLUE}Processing: $file${NC}"
    echo -e "Original size: ${YELLOW}${original_size} MB${NC}"
    
    # Check if file is already under target size
    if (( $(echo "$original_size <= $TARGET_SIZE_MB" | bc -l) )); then
        echo -e "${GREEN}File is already under ${TARGET_SIZE_MB}MB${NC}"
        remove_from_gitignore "$file"
        return 0
    fi
    
    # Create backup if enabled
    if [ "$BACKUP" = true ]; then
        local backup_file="${file%.pdf}.backup.pdf"
        if [ ! -f "$backup_file" ]; then
            cp "$file" "$backup_file"
            echo -e "Backup created: $backup_file"
        fi
    fi
    
    # Try different compression levels
    local temp_file="${file%.pdf}.temp.pdf"
    local qualities=("screen" "ebook" "printer")
    local success=false
    
    for quality in "${qualities[@]}"; do
        echo -e "Trying $quality compression..."
        
        if compress_pdf "$file" "$temp_file" "$quality"; then
            local compressed_size=$(get_size_mb "$temp_file")
            echo -e "Compressed size ($quality): ${YELLOW}${compressed_size} MB${NC}"
            
            if (( $(echo "$compressed_size <= $TARGET_SIZE_MB" | bc -l) )); then
                mv "$temp_file" "$file"
                echo -e "${GREEN}✅ Successfully compressed to ${compressed_size} MB${NC}"
                remove_from_gitignore "$file"
                success=true
                break
            fi
        fi
        
        # Clean up temp file
        [ -f "$temp_file" ] && rm "$temp_file"
    done
    
    if [ "$success" = false ]; then
        echo -e "${RED}❌ Could not compress below ${TARGET_SIZE_MB}MB, adding to .gitignore${NC}"
        add_to_gitignore "$file"
        return 1
    fi
    
    return 0
}

# Function to find large PDFs
find_large_pdfs() {
    local count=0
    while IFS= read -r -d '' file; do
        local size=$(get_size_mb "$file")
        if (( $(echo "$size > $TARGET_SIZE_MB" | bc -l) )); then
            echo "$file"
            ((count++))
        fi
    done < <(find . -name "*.pdf" -type f -print0)
    
    return $count
}

# Main function
main() {
    echo -e "${BLUE}PDF Compressor for Git Repository${NC}"
    echo "========================================"
    
    # Check if required tools are available
    if ! command -v gs &> /dev/null; then
        echo -e "${RED}Error: Ghostscript not found${NC}"
        echo "Install with:"
        echo "  Ubuntu/Debian: sudo apt-get install ghostscript"
        echo "  macOS: brew install ghostscript"
        exit 1
    fi
    
    if ! command -v bc &> /dev/null; then
        echo -e "${RED}Error: bc calculator not found${NC}"
        echo "Install with:"
        echo "  Ubuntu/Debian: sudo apt-get install bc"
        echo "  macOS: brew install bc"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Ghostscript found${NC}"
    
    # Find large PDFs
    echo -e "\nSearching for PDFs larger than ${TARGET_SIZE_MB}MB..."
    
    local large_pdfs=()
    while IFS= read -r file; do
        large_pdfs+=("$file")
    done < <(find_large_pdfs)
    
    if [ ${#large_pdfs[@]} -eq 0 ]; then
        echo -e "${GREEN}No PDFs found larger than ${TARGET_SIZE_MB}MB${NC}"
        exit 0
    fi
    
    echo -e "Found ${YELLOW}${#large_pdfs[@]}${NC} large PDFs:"
    for file in "${large_pdfs[@]}"; do
        local size=$(get_size_mb "$file")
        echo -e "  $file (${YELLOW}${size} MB${NC})"
    done
    
    # Ask for confirmation
    echo -n -e "\nProcess ${#large_pdfs[@]} PDFs? (y/n): "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
    
    # Process each PDF
    local successful=0
    local failed=0
    
    for file in "${large_pdfs[@]}"; do
        if process_pdf "$file"; then
            ((successful++))
        else
            ((failed++))
        fi
    done
    
    echo -e "\n========================================"
    echo -e "${GREEN}Processing complete!${NC}"
    echo -e "Successfully compressed: ${GREEN}$successful${NC}"
    echo -e "Added to .gitignore: ${RED}$failed${NC}"
    
    if [ $failed -gt 0 ]; then
        echo -e "\n${YELLOW}Files that couldn't be compressed enough are now in .gitignore${NC}"
        echo "You may want to consider using Git LFS for these large files:"
        echo "  git lfs track '*.pdf'"
    fi
}

# Check if script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
