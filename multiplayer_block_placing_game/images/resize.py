from PIL import Image
import os

def resize_image(image_path, max_size=128):
    # Open the image
    img = Image.open(image_path)
    
    # Get current dimensions
    width, height = img.size
    
    # Calculate new dimensions to maintain aspect ratio
    if width > height:
        new_width = max_size
        new_height = int(height * (max_size / width))
    else:
        new_height = max_size
        new_width = int(width * (max_size / height))
    
    # Resize the image
    resized_img = img.resize((new_width, new_height), Image.LANCZOS)
    
    # Save the image, overwriting the original
    resized_img.save(image_path)
    print(f"Resized {image_path} to {new_width}x{new_height}")

def main():
    # Get list of PNG files in current directory
    png_files = [f for f in os.listdir('./') if f.lower().endswith('.png')]
    
    if not png_files:
        print("No PNG files found in the current directory.")
        return
    
    print(f"Found {len(png_files)} PNG files. Starting resize process...")
    
    # Process each PNG file
    for png_file in png_files:
        file_path = os.path.join('./', png_file)
        try:
            resize_image(file_path)
        except Exception as e:
            print(f"Error processing {file_path}: {e}")
    
    print("Resize process completed.")

if __name__ == "__main__":
    main()
