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

def process_csv_and_download(csv_path, base_output_dir='./downloaded'):
    """Process CSV file and download only PechaKucha images and PDF files for students who participated in PechaKucha"""
    # Authenticate
    service = authenticate_google_drive()
    
    # Create base output directory if it doesn't exist
    if not os.path.exists(base_output_dir):
        os.makedirs(base_output_dir)
    
    # Define column groups for different year PechaKucha images - excluding DTS
    pechakucha_columns = {
        'Y1': [
            '(Y1S1Pk1) first image',
            '(Y1S1Pk2) second image',
            '(Y1S1Pk3) third image',
            '(Y1S1Pk4) fourth image',
            '(Y1S1Pk5) fifth image'
        ],
        'Y2/3': [
            '(Y2/3S1Pk1) first image',
            '(Y2/3S1Pk2) second image',
            '(Y2/3S1Pk3) third image',
            '(Y2/3S1Pk4) fourth image',
            '(Y2/3S1Pk5) fifth image'
        ],
        'Y4': [
            '(Y4S1Pk1) first image',
            '(Y4S1Pk2) second image',
            '(Y4S1Pk3) third image',
            '(Y4S1Pk4) fourth image',
            '(Y4S1Pk5) fifth image'
        ]
    }
    
    # PDF column (for any student)
    pdf_column = ' .PDF file briefly explaining your design studio project (max 10MB -easy read on mobile)'
    
    # Read the CSV file
    with open(csv_path, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        
        for row in reader:
            email = row['Email Address']
            student_img_dir = os.path.join(base_output_dir, email, 'IMG')
            student_pdf_dir = os.path.join(base_output_dir, email, 'PDF')
            
            # Check if student specifically participated in PechaKucha (has at least one PK image)
            has_pechakucha = False
            
            for year_group, columns in pechakucha_columns.items():
                for column in columns:
                    if column in row and row[column] and row[column].strip() != "":
                        has_pechakucha = True
                        break
                if has_pechakucha:
                    break
            
            # Process student if they participated in PechaKucha
            if has_pechakucha:
                print(f"\nProcessing student: {email} (PechaKucha participant)")
                
                # Process only PechaKucha images (no DTS)
                for year_group, columns in pechakucha_columns.items():
                    for i, column in enumerate(columns, 1):
                        if column in row:  # Make sure column exists in CSV
                            link = row[column]
                            file_id = extract_file_id(link)
                            
                            if file_id:
                                try:
                                    # Get file metadata
                                    file_metadata = service.files().get(fileId=file_id, fields="name").execute()
                                    file_name = file_metadata.get('name', f'{year_group}Pk{i}')
                                    
                                    # Download the file
                                    output_path = os.path.join(student_img_dir, file_name)
                                    print(f"Processing {year_group}Pk{i} image: {file_name}...")
                                    if download_file(service, file_id, output_path):
                                        print(f"Downloaded to {output_path}")
                                except Exception as e:
                                    print(f"Error downloading {year_group}Pk{i} image: {e}")
                
                # Download PDF file if available
                if pdf_column in row:
                    pdf_link = row[pdf_column]
                    pdf_file_id = extract_file_id(pdf_link)
                    
                    if pdf_file_id:
                        try:
                            # Get file metadata for PDF
                            pdf_metadata = service.files().get(fileId=pdf_file_id, fields="name").execute()
                            pdf_name = pdf_metadata.get('name', 'project_description.pdf')
                            
                            # Download the PDF file
                            pdf_output_path = os.path.join(student_pdf_dir, pdf_name)
                            print(f"Processing PDF: {pdf_name}...")
                            if download_file(service, pdf_file_id, pdf_output_path):
                                print(f"Downloaded to {pdf_output_path}")
                        except Exception as e:
                            print(f"Error downloading PDF: {e}")
            else:
                print(f"Skipping student {email} - not a PechaKucha participant")

if __name__ == "__main__":
    # Path to your CSV file - adjust as needed
    csv_file_path = "parade_sem1.csv"
    
    # Process the CSV and download files
    process_csv_and_download(csv_file_path)
