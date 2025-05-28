# app.py








from flask import Flask, request, render_template, jsonify, send_from_directory
import os
import requests
import base64
import qrcode
import time






# Add these at the beginning of app.py
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__, static_url_path='', static_folder='.')
app.wsgi_app = ProxyFix(app.wsgi_app)

# Increase both the Flask and server-side request limits
app.config['MAX_CONTENT_LENGTH'] = 32 * 1024 * 1024  # 32MB





# Configure Flask to handle larger file uploads
app = Flask(__name__, static_url_path='', static_folder='.')
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16 MB limit

os.makedirs('uploads', exist_ok=True)
os.makedirs('static/qrcodes', exist_ok=True)

@app.route('/')
def index():
    return send_from_directory('.', 'index.html')






@app.route('/generate-qr', methods=['POST'])
def generate_qr():
    try:
        image_data = request.form.get('image_data')
        if not image_data:
            return jsonify({'success': False, 'error': 'No image data provided'})
        
        # Make sure we're handling the image format correctly
        if 'data:image/png;base64,' in image_data:
            image_data = image_data.replace('data:image/png;base64,', '')
        elif 'data:image/jpeg;base64,' in image_data:
            image_data = image_data.replace('data:image/jpeg;base64,', '')
        
        timestamp = int(time.time())
        image_filename = f'imagen_{timestamp}.png'
        qr_filename = f'imagen_{timestamp}_qr.png'
        
        image_path = os.path.join('uploads', image_filename)
        
        # Decode and save the image
        try:
            image_bytes = base64.b64decode(image_data)
            with open(image_path, 'wb') as f:
                f.write(image_bytes)
            
            # Verify the image was saved properly
            if not os.path.exists(image_path) or os.path.getsize(image_path) < 100:
                return jsonify({'success': False, 'error': 'Failed to save image or image is too small'})
        except Exception as e:
            return jsonify({'success': False, 'error': f'Error saving image: {str(e)}'})
        
        # Upload to ImgBB
        try:
            with open(image_path, 'rb') as f:
                files = {'image': f}
                imgbb_response = requests.post(
                    'https://api.imgbb.com/1/upload?key=a827f127d1a994df55b303b9ade745ad',
                    files=files
                )
            
            imgbb_data = imgbb_response.json()
            if not imgbb_data.get('success'):
                return jsonify({'success': False, 'error': 'Failed to upload to ImgBB'})
            
            image_url = imgbb_data['data']['image']['url']
        except Exception as e:
            return jsonify({'success': False, 'error': f'Error uploading to ImgBB: {str(e)}'})
        
        # Generate QR code
        try:
            qr = qrcode.QRCode(
                version=1,
                error_correction=qrcode.constants.ERROR_CORRECT_L,
                box_size=10,
                border=4,
            )
            qr.add_data(image_url)
            qr.make(fit=True)
            
            qr_img = qr.make_image(fill_color="black", back_color="white")
            
            qr_path = os.path.join('static', 'qrcodes', qr_filename)
            qr_img.save(qr_path)
        except Exception as e:
            return jsonify({'success': False, 'error': f'Error generating QR code: {str(e)}'})
        
        return jsonify({
            'success': True,
            'qr_code': f'/static/qrcodes/{qr_filename}',
            'original_image': image_url
        })
        
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})









if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
