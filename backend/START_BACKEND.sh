#!/bin/bash
# OmeChat Backend - Universal Start Script
# Tüm cihazlardan erişilebilir

echo "============================================================"
echo "OmeChat Backend Starting..."
echo "============================================================"
echo "Host: 0.0.0.0 (All interfaces)"
echo "Port: 8000"
echo ""
echo "Accessible from:"
echo "  - Local: http://localhost:8000"
echo "  - Network: http://192.168.1.103:8000"
echo "  - All devices on same network"
echo "============================================================"
echo ""

cd "$(dirname "$0")"
python3 start_backend.py





