#!/bin/bash

# Set the dimensions - 3:1 aspect ratio
WIDTH=60
HEIGHT=20
FRAMES=100

# Create temporary directory
TEMP_DIR="sprite_frames"
mkdir -p $TEMP_DIR

echo "Generating $FRAMES frames with just frame numbers..."

for i in $(seq 0 $((FRAMES-1))); do
    FRAME_NUM=$((i+1))
    
    # Create a simple image with just the frame number
    convert -size ${WIDTH}x${HEIGHT} xc:black \
        -fill white -font "Courier" -pointsize 14 -gravity center \
        -annotate +0+0 "$FRAME_NUM" \
        "$TEMP_DIR/frame_$(printf "%03d" $i).png"
done

# Create horizontal sprite sheet
echo "Creating sprite sheet..."
convert "$TEMP_DIR/frame_"*.png +append led.png

# Clean up
rm -rf $TEMP_DIR

echo "Done!"
