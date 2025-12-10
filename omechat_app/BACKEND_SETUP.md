# Backend Kurulum ve Yapılandırma

## ÖNEMLİ: Telefonların Birbirini Bulması İçin

### 1. Backend'i Başlatın

Backend klasöründe:
```bash
cd backend
# Virtual environment aktif edin (Windows)
venv\Scripts\activate

# Backend'i başlatın
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Backend `http://0.0.0.0:8000` adresinde çalışmalı.

### 2. PC IP Adresinizi Bulun

Windows PowerShell'de:
```powershell
ipconfig
```

"IPv4 Address" değerini bulun (örn: `192.168.1.103`)

### 3. Flutter Uygulamasında IP'yi Ayarlayın

`omechat_app/lib/services/api_client.dart` dosyasında:

```dart
final apiClientProvider = Provider<ApiClient>((ref) {
  // Gerçek telefonlar için PC IP'nizi kullanın:
  return ApiClient(baseUrl: 'http://192.168.1.103:8000');  // IP'nizi buraya yazın!
  
  // Android Emulator için:
  // return ApiClient(baseUrl: 'http://10.0.2.2:8000');
});
```

### 4. Firewall Ayarları

Windows Firewall'da port 8000'i açmanız gerekebilir:
```powershell
# PowerShell (Admin olarak)
New-NetFirewallRule -DisplayName "OmeChat Backend" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow
```

### 5. Test

1. Backend'in çalıştığını kontrol edin: http://localhost:8000
2. Telefonlar aynı Wi-Fi ağında olmalı
3. Her iki telefonda da uygulamayı başlatın
4. Online sayısı artmalı ve eşleşme olmalı

## Sorun Giderme

### "0 çevrimiçi" görünüyorsa:

1. ✅ Backend çalışıyor mu? → http://localhost:8000 kontrol edin
2. ✅ PC IP doğru mu? → `ipconfig` ile kontrol edin
3. ✅ Telefonlar aynı Wi-Fi'de mi?
4. ✅ Firewall port 8000'i engelliyor mu?
5. ✅ API URL doğru mu? → `api_client.dart` kontrol edin

### Debug Logları

Flutter console'da şunları görmelisiniz:
- `API Log: ...` → API istekleri
- `WS Connecting to: ...` → WebSocket bağlantıları
- `WS Received: ...` → WebSocket mesajları

Backend console'da:
- Session oluşturma logları
- WebSocket bağlantı logları
- Matchmaking logları



