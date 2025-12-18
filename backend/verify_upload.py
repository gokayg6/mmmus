
import requests
import sys

BASE_URL = "http://localhost:8000/api/v1"

def test_upload():
    # 1. Login
    print("Logging in...")
    try:
        login_resp = requests.post(
            f"{BASE_URL}/auth/login",
            data={"username": "gokay", "password": "gokay777"}
        )
        if login_resp.status_code != 200:
            print(f"Login failed: {login_resp.text}")
            return
        
        token = login_resp.json()["access_token"]
        print("Login successful. Token obtained.")
        
        # 2. Upload
        print("Uploading file...")
        files = {
            'file': ('test_avatar.jpg', b'fake image content', 'image/jpeg')
        }
        headers = {
            'Authorization': f'Bearer {token}'
        }
        
        upload_resp = requests.post(
            f"{BASE_URL}/upload/avatar",
            files=files,
            headers=headers
        )
        
        print(f"Upload Status: {upload_resp.status_code}")
        print(f"Upload Response: {upload_resp.text}")
        
    except Exception as e:
        print(f"Test failed: {e}")

if __name__ == "__main__":
    test_upload()
