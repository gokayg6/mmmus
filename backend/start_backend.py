"""
OmeChat Backend - Universal Start Script
Tüm cihazlardan erişilebilir backend başlatıcı
"""
import uvicorn
import sys
import os

# Backend dizinine geç ve PYTHONPATH'e ekle
backend_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(backend_dir)
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

if __name__ == "__main__":
    print("=" * 60)
    print("OmeChat Backend Starting...")
    print("=" * 60)
    print("Host: 0.0.0.0 (All interfaces)")
    print("Port: 8000")
    print("Accessible from:")
    print("  - Local: http://localhost:8000")
    print("  - Network: http://192.168.1.103:8000")
    print("  - All devices on same network")
    print("=" * 60)
    
    try:
        uvicorn.run(
            "app.main:app",
            host="0.0.0.0",
            port=8000,
            reload=False,  # Production mode
            log_level="info",
            access_log=True,
        )
    except KeyboardInterrupt:
        print("\nBackend stopped by user")
    except Exception as e:
        print(f"Error starting backend: {e}")
        sys.exit(1)

