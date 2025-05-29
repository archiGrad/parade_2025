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

def count_pk_students(csv_path):
    """Count students who are presenting Pecha Kucha"""
    pk_count = 0
    pk_students = []
    
    with open(csv_path, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            email = row['Email Address']
            year = row['Which year are you currently in?']
            
            # Check if student is presenting for Pecha Kucha
            has_pk = False
            if year in ['Y1', 'Y2', 'Y3']:
                pk_column = row['(Y1/2/3) Are you presenting your project for PechaKucha in semester 2?  ']
                has_pk = pk_column and pk_column.lower() == 'yes'
            elif year == 'Y4':
                pk_column = row['(Y4) Were you presenting your project for PechaKucha in semester 2?']
                has_pk = pk_column and pk_column.lower() == 'yes'
            
            if has_pk:
                pk_count += 1
                pk_students.append({'email': email, 'year': year, 'name': row['what is your full name?']})
    
    print(f"Total Pecha Kucha students: {pk_count}")
    print("\nPecha Kucha students list:")
    for i, student in enumerate(pk_students):
        print(f"{i+1}. {student['email']} - {student['year']} - {student['name']}")
    
    return pk_count, pk_students

def process_csv_and_download(csv_path, base_output_dir='./downloaded'):
    """Process CSV file and download Pecha Kucha images and PDF files for each student"""
    # First count PK students
    pk_count, pk_students = count_pk_students(csv_path)
    
    # Authenticate
    service = authenticate_google_drive()
    
    # Create base output directory if it doesn't exist
    if not os.path.exists(base_output_dir):
        os.makedirs(base_output_dir)
    
    # Read the CSV file and process only PK students
    with open(csv_path, 'r', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            email = row['Email Address']
            year = row['Which year are you currently in?']
            
            # Check if this student is presenting Pecha Kucha
            has_pk = False
            if year in ['Y1', 'Y2', 'Y3']:
                pk_column = row['(Y1/2/3) Are you presenting your project for PechaKucha in semester 2?  ']
                has_pk = pk_column and pk_column.lower() == 'yes'
            elif year == 'Y4':
                pk_column = row['(Y4) Were you presenting your project for PechaKucha in semester 2?']
                has_pk = pk_column and pk_column.lower() == 'yes'
            
            # Only process if student has Pecha Kucha
            if has_pk:
                print(f"\nProcessing PK student: {email} ({year})")
                
                # Create directories for this student
                student_img_dir = os.path.join(base_output_dir, email, 'IMG')
                student_pdf_dir = os.path.join(base_output_dir, email, 'PDF')
                
                # Process all 10 Pecha Kucha images based on year
                if year in ['Y1', 'Y2', 'Y3']:
                    pk_columns = [
                        '(Y1/2/3S2Pk1) first image',
                        '(Y1/2/3S2Pk2) second image',
                        '(Y1/2/3S2Pk3) third image',
                        '(Y1/2/3S2Pk4) fourth image',
                        '(Y1/2/3S2Pk5) fifth image',
                        '(Y1/2/3S2Pk6) sixth image',
                        '(Y1/2/3S2Pk7) seventh image',
                        '(Y1/2/3S2Pk8) eight image',
                        '(Y1/2/3S2Pk9) nineth image',
                        '(Y1/2/3S2Pk10) tenth image'
                    ]
                elif year == 'Y4':
                    pk_columns = [
                        '(Y4S2Pk1) first image',
                        '(Y4S2Pk2) second image',
                        '(Y4S2Pk3) third image',
                        '(Y4S2Pk4) fourth image',
                        '(Y4S2Pk5) fifth image',
                        '(Y4S2Pk6) sixth image',
                        '(Y4S2Pk7) seventh image',
                        '(Y4S2Pk8) eight image',
                        '(Y4S2Pk9) nineth image',
                        '(Y4S2Pk10) tenth image'
                    ]
                
                # Download all PK images
                for i, column in enumerate(pk_columns):
                    image_link = row[column]
                    image_file_id = extract_file_id(image_link)
                    
                    if image_file_id:
                        try:
                            # Get file metadata to determine file name and extension
                            file_metadata = service.files().get(fileId=image_file_id, fields="name").execute()
                            file_name = file_metadata.get('name', f'pk_image_{i+1}')
                            
                            # Download the file
                            output_path = os.path.join(student_img_dir, file_name)
                            print(f"Downloading PK image {i+1}: {file_name}...")
                            if download_file(service, image_file_id, output_path):
                                print(f"Downloaded to {output_path}")
                        except Exception as e:
                            print(f"Error downloading PK image {i+1}: {e}")
                    else:
                        print(f"No PK image {i+1} found")
                
                # Process PDF file (QRPDF1)
                pdf_link = row['(QRPDF1) upload pdf booklet']
                pdf_file_id = extract_file_id(pdf_link)
                
                if pdf_file_id:
                    try:
                        # Get file metadata for PDF
                        pdf_metadata = service.files().get(fileId=pdf_file_id, fields="name").execute()
                        pdf_name = pdf_metadata.get('name', 'project_description.pdf')
                        
                        # Download the PDF file
                        pdf_output_path = os.path.join(student_pdf_dir, pdf_name)
                        print(f"Downloading PDF: {pdf_name}...")
                        if download_file(service, pdf_file_id, pdf_output_path):
                            print(f"Downloaded to {pdf_output_path}")
                    except Exception as e:
                        print(f"Error downloading PDF: {e}")
                else:
                    print("No PDF file found")

if __name__ == "__main__":
    # Path to your CSV file - adjust as needed
    csv_file_path = "parade_sem2.csv"
    
    # Process the CSV and download files
    process_csv_and_download(csv_file_path)
