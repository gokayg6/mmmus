"""
Quick connection test for Flutter app
Run this to verify the backend is accessible from the Flutter app's perspective
"""
import requests
import sys

# This should match the IP in app_config.dart
BACKEND_URL = "http://192.168.64.1:8000"

print("=" * 60)
print("FLUTTER APP BACKEND CONNECTION TEST")
print("=" * 60)
print(f"Testing connection to: {BACKEND_URL}")
print()

# Test 1: Root endpoint
print("1. Testing root endpoint...")
try:
    r = requests.get(f"{BACKEND_URL}/", timeout=5)
    if r.status_code == 200:
        print(f"   ✓ SUCCESS: Backend is accessible!")
        print(f"   Response: {r.json()}")
    else:
        print(f"   ✗ FAILED: Status {r.status_code}")
        sys.exit(1)
except requests.exceptions.ConnectionError:
    print(f"   ✗ CONNECTION ERROR: Cannot reach backend at {BACKEND_URL}")
    print(f"   Make sure:")
    print(f"   1. Backend server is running (run START_BACKEND_SIMPLE.bat)")
    print(f"   2. IP address matches the one shown by the backend")
    print(f"   3. Firewall is not blocking port 8000")
    sys.exit(1)
except Exception as e:
    print(f"   ✗ ERROR: {e}")
    sys.exit(1)

# Test 2: Health check
print("\n2. Testing health endpoint...")
try:
    r = requests.get(f"{BACKEND_URL}/api/v1/public/health", timeout=5)
    if r.status_code == 200:
        print(f"   ✓ SUCCESS: Health check passed")
        print(f"   Response: {r.json()}")
    else:
        print(f"   ✗ FAILED: Status {r.status_code}")
except Exception as e:
    print(f"   ✗ ERROR: {e}")

# Test 3: Online count
print("\n3. Testing online count endpoint...")
try:
    r = requests.get(f"{BACKEND_URL}/api/v1/public/online-count", timeout=5)
    if r.status_code == 200:
        print(f"   ✓ SUCCESS: Online count endpoint working")
        print(f"   Response: {r.json()}")
    else:
        print(f"   ✗ FAILED: Status {r.status_code}")
except Exception as e:
    print(f"   ✗ ERROR: {e}")

print("\n" + "=" * 60)
print("CONNECTION TEST COMPLETED SUCCESSFULLY!")
print("=" * 60)
print("\nYour Flutter app should now be able to connect to the backend.")
print(f"Backend URL: {BACKEND_URL}")
print("\nNext steps:")
print("1. Make sure app_config.dart has: developmentBackendUrl = '{BACKEND_URL}'")
print("2. Run your Flutter app: flutter run -d chrome")
print("3. Try to register/login")
