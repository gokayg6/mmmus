
import sys
import os
import traceback

# Backend dizinini ayarla
backend_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(backend_dir)
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

try:
    print("Attempting to import app.main...")
    from app import main
    print("Import successful!")
except Exception:
    print("Import failed!")
    traceback.print_exc()
