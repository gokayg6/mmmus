"""
Simple diagnostic test for authentication
"""
import requests
import json

BASE_URL = "http://localhost:8000"

print("=" * 60)
print("DIAGNOSTIC TEST - AUTHENTICATION")
print("=" * 60)

# Test 1: Root endpoint
print("\n1. Testing root endpoint...")
try:
    r = requests.get(f"{BASE_URL}/")
    print(f"   ✓ Status: {r.status_code}")
    print(f"   Response: {r.json()}")
except Exception as e:
    print(f"   ✗ Error: {e}")
    exit(1)

# Test 2: Register new user with unique email
import time
email = f"test{int(time.time())}@example.com"
username = f"user{int(time.time())}"
password = "testpass123"

print(f"\n2. Testing registration...")
print(f"   Email: {email}")
print(f"   Username: {username}")
print(f"   Password: {password}")

try:
    r = requests.post(
        f"{BASE_URL}/api/v1/auth/register",
        json={"email": email, "username": username, "password": password}
    )
    print(f"   Status: {r.status_code}")
    print(f"   Response: {r.text[:200]}")
    
    if r.status_code == 201:
        data = r.json()
        token = data.get("access_token")
        print(f"   ✓ Registration successful!")
        print(f"   Token: {token[:30]}...")
    else:
        print(f"   ✗ Registration failed!")
        exit(1)
except Exception as e:
    print(f"   ✗ Error: {e}")
    exit(1)

# Test 3: Login with same credentials
print(f"\n3. Testing login...")
print(f"   Email: {email}")
print(f"   Password: {password}")

try:
    r = requests.post(
        f"{BASE_URL}/api/v1/auth/login",
        json={"email": email, "password": password}
    )
    print(f"   Status: {r.status_code}")
    print(f"   Response: {r.text[:200]}")
    
    if r.status_code == 200:
        data = r.json()
        token = data.get("access_token")
        print(f"   ✓ Login successful!")
        print(f"   Token: {token[:30]}...")
    else:
        print(f"   ✗ Login failed!")
        print(f"   Full response: {r.text}")
        exit(1)
except Exception as e:
    print(f"   ✗ Error: {e}")
    exit(1)

# Test 4: Get current user
print(f"\n4. Testing get current user...")
try:
    r = requests.get(
        f"{BASE_URL}/api/v1/auth/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    print(f"   Status: {r.status_code}")
    
    if r.status_code == 200:
        data = r.json()
        print(f"   ✓ Get user successful!")
        print(f"   User: {data.get('username')} ({data.get('email')})")
    else:
        print(f"   ✗ Get user failed!")
        print(f"   Response: {r.text}")
except Exception as e:
    print(f"   ✗ Error: {e}")

# Test 5: Create anonymous session
print(f"\n5. Testing create session...")
try:
    r = requests.post(
        f"{BASE_URL}/api/v1/session/create",
        json={"gender": "MALE", "country": "TR"}
    )
    print(f"   Status: {r.status_code}")
    print(f"   Response: {r.text[:200]}")
    
    if r.status_code == 200:
        data = r.json()
        session_token = data.get("session_token")
        print(f"   ✓ Session created!")
        print(f"   Session token: {session_token[:30]}...")
    else:
        print(f"   ⚠ Session creation failed (might not be implemented)")
        print(f"   Response: {r.text}")
except Exception as e:
    print(f"   ✗ Error: {e}")

print("\n" + "=" * 60)
print("DIAGNOSTIC TEST COMPLETED")
print("=" * 60)
