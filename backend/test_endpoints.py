"""
Test script to verify backend endpoints
"""
import requests
import json

BASE_URL = "http://localhost:8000"

def test_root():
    """Test root endpoint"""
    print("\n=== Testing Root Endpoint ===")
    try:
        response = requests.get(f"{BASE_URL}/")
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_register():
    """Test user registration"""
    print("\n=== Testing Registration ===")
    try:
        data = {
            "email": "test@example.com",
            "username": "testuser",
            "password": "testpass123"
        }
        response = requests.post(
            f"{BASE_URL}/api/v1/auth/register",
            json=data,
            headers={"Content-Type": "application/json"}
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 201:
            result = response.json()
            print(f"Token: {result.get('access_token', 'N/A')[:50]}...")
            print(f"User: {result.get('user', {}).get('username')}")
            return True, result.get('access_token')
        else:
            return False, None
    except Exception as e:
        print(f"Error: {e}")
        return False, None

def test_login():
    """Test user login"""
    print("\n=== Testing Login ===")
    try:
        data = {
            "email": "test@example.com",
            "password": "testpass123"
        }
        response = requests.post(
            f"{BASE_URL}/api/v1/auth/login",
            json=data,
            headers={"Content-Type": "application/json"}
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"Token: {result.get('access_token', 'N/A')[:50]}...")
            print(f"User: {result.get('user', {}).get('username')}")
            return True, result.get('access_token')
        else:
            return False, None
    except Exception as e:
        print(f"Error: {e}")
        return False, None

def test_get_me(token):
    """Test getting current user"""
    print("\n=== Testing Get Me ===")
    try:
        response = requests.get(
            f"{BASE_URL}/api/v1/auth/me",
            headers={"Authorization": f"Bearer {token}"}
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_create_session(token):
    """Test creating anonymous session"""
    print("\n=== Testing Create Session ===")
    try:
        data = {
            "gender": "MALE",
            "country": "TR"
        }
        response = requests.post(
            f"{BASE_URL}/api/v1/session/create",
            json=data,
            headers={"Content-Type": "application/json"}
        )
        print(f"Status: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"Session Token: {result.get('session_token', 'N/A')[:50]}...")
            return True, result.get('session_token')
        else:
            return False, None
    except Exception as e:
        print(f"Error: {e}")
        return False, None

if __name__ == "__main__":
    print("=" * 60)
    print("OMECHAT BACKEND ENDPOINT TESTS")
    print("=" * 60)
    
    # Test root
    if not test_root():
        print("\n❌ Root endpoint failed - server might not be running")
        exit(1)
    
    print("\n✅ Root endpoint OK")
    
    # Test registration
    success, token = test_register()
    if success:
        print("\n✅ Registration OK")
    else:
        print("\n⚠️ Registration failed (might be duplicate user)")
    
    # Test login
    success, token = test_login()
    if success:
        print("\n✅ Login OK")
    else:
        print("\n❌ Login failed")
        exit(1)
    
    # Test get me
    if test_get_me(token):
        print("\n✅ Get Me OK")
    else:
        print("\n❌ Get Me failed")
    
    # Test create session
    success, session_token = test_create_session(token)
    if success:
        print("\n✅ Create Session OK")
    else:
        print("\n❌ Create Session failed")
    
    print("\n" + "=" * 60)
    print("TESTS COMPLETED")
    print("=" * 60)
