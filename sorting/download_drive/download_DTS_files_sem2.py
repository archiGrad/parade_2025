import json
import os
import io
import csv
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.http import MediaIoBaseDownload

# Define scopes - we need drive scope to access files
SCOPES = ['https://www.googleapis.com/auth/drive.readonly']

def authenticate_google_drive():
    """Authenticate with Google Drive API using OAuth 2.0"""
    creds = None
    
    # Check if token file exists
    if os.path.exists('token.json'):
        creds = Credentials.from_authorized_user_info(
            json.loads(open('token.json').read()), SCOPES)
    
    # If no valid credentials available, authenticate
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                'credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        
        # Save the credentials for the next run
        with open('token.json', 'w') as token:
            token.write(creds.to_json())
            
    return build('drive', 'v3', credentials=creds)

def download_file(service, file_id, output_path):
    """Download a file from Google Drive"""
    # Ensure the directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Check if file already exists
    if os.path.exists(output_path):
        print(f"File already exists: {output_path}")
        return False
    
    request = service.files().get_media(fileId=file_id)
    
    with open(output_path, 'wb') as f:
        downloader = MediaIoBaseDownload(f, request)
        done = False
        while done is False:
            status, done = downloader.next_chunk()
            print(f"Download {int(status.progress() * 100)}%.")
    
    return True

def extract_file_id(drive_link):
    """Extract file ID from a Google Drive link"""
    # Handle different link formats
    if not drive_link or drive_link.strip() == "":
        return None
        
    if '/file/d/' in drive_link:
        return drive_link.split('/file/d/')[1].split('/')[0]
    elif 'id=' in drive_link:
        return drive_link.split('id=')[1].split('&')[0]
    elif '/open?id=' in drive_link:
        return drive_link.split('/open?id=')[1].split('&')[0]
    return None

def create_empty_file(file_path):
    """Create an empty file at the specified path"""
    # Ensure the directory exists
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    
    # Create the empty file if it doesn't exist
    if not os.path.exists(file_path):
        with open(file_path, 'w') as f:
            pass  # Create empty file
        print(f"Created empty file: {file_path}")
    else:
        print(f"File already exists: {file_path}")

def process_dts_images(csv_path, base_output_dir='./downloaded'):
    """Process CSV file and download DTS images for each student"""
    # Authenticate
    service = authenticate_google_drive()
    
    # Create base output directory if it doesn't exist
    if not os.path.exists(base_output_dir):
        os.makedirs(base_output_dir)
    
    # Read the CSV file
    with open(csv_path, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            email = row['Email Address']
            
            # Create directories for this student
            student_img_dir = os.path.join(base_output_dir, email, 'IMG')
            student_pdf_dir = os.path.join(base_output_dir, email, 'PDF')
            
            # Process DTS images
            dts_links = [row.get('(DTS1) first image', ''), 
                        row.get('(DTS2) second image', ''), 
                        row.get('(DTS3) third image', '')]
            
            # Check if at least one DTS image exists
            has_dts_image = any(link and link.strip() != "" for link in dts_links)
            
            if has_dts_image:
                print(f"\nProcessing student: {email}")
                
                # Download DTS images
                for i, link in enumerate(dts_links, 1):
                    file_id = extract_file_id(link)
                    if not file_id:
                        print(f"No valid link for DTS{i} image")
                        continue
                    
                    # Get file metadata to determine file name and extension
                    try:
                        file_metadata = service.files().get(fileId=file_id, fields="name").execute()
                        file_name = file_metadata.get('name', f'DTS{i}')
                        
                        # Download the file
                        output_path = os.path.join(student_img_dir, file_name)
                        print(f"Processing DTS{i} image: {file_name}...")
                        if download_file(service, file_id, output_path):
                            print(f"Downloaded to {output_path}")
                    except Exception as e:
                        print(f"Error downloading DTS{i} image: {e}")
                
                # Create empty link.txt file in PDF directory
                empty_file_path = os.path.join(student_pdf_dir, 'link.txt')
                create_empty_file(empty_file_path)
            else:
                print(f"Skipping student {email} - no DTS images found")

if __name__ == "__main__":
    # Path to your CSV file - adjust as needed
    csv_file_path = "DTS2_submission_2.csv"
    
    # Process the CSV and download files
    process_dts_images(csv_file_path)
