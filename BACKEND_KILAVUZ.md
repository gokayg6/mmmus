# OmeChat Backend - Hızlı Başlangıç Kılavuzu

## Backend'i Başlatma

1. `backend` klasörüne gidin
2. `START_BACKEND_SIMPLE.bat` dosyasını çalıştırın
3. Gösterilen **AĞ IP adresini** not edin (örn: `http://192.168.64.1:8000`)
4. Pencereyi açık tutun

## Flutter Uygulamasını Yapılandırma

1. `omechat_app/lib/core/config/app_config.dart` dosyasını açın
2. `developmentBackendUrl` değerini backend'in gösterdiği IP ile güncelleyin:
   ```dart
   static const String developmentBackendUrl = 'http://192.168.64.1:8000';
   ```
3. Dosyayı kaydedin

## Flutter Uygulamasını Çalıştırma

```bash
cd omechat_app
flutter run -d chrome
```

veya Windows için:

```bash
flutter run -d windows
```

## Test Etme

### 1. Kayıt (Registration)
- Uygulamayı açın
- "Kayıt Ol" butonuna tıklayın
- Email, kullanıcı adı ve şifre girin
- Kayıt başarılı olmalı

### 2. Giriş (Login)
- Kayıtlı email ve şifrenizi girin
- Giriş başarılı olmalı

### 3. Eşleşme (Matchmaking)
- Giriş yaptıktan sonra oturum başlatın
- Eşleşme kuyruğuna katılın
- Online kullanıcı sayısı görünmeli

## Sorun Giderme

### Backend'e bağlanamıyorum
1. Backend sunucusunun çalıştığından emin olun
2. `app_config.dart` dosyasındaki IP adresinin doğru olduğunu kontrol edin
3. Firewall'un 8000 portunu engellemediğini kontrol edin
4. Backend penceresinde bağlantı loglarını kontrol edin

### Kayıt/Giriş çalışmıyor
1. Backend loglarında hata mesajlarını kontrol edin
2. Browser console'da (F12) hata mesajlarını kontrol edin
3. Backend'in doğru IP adresinde çalıştığını doğrulayın

### WebSocket bağlanamıyor
1. Backend'in çalıştığından emin olun
2. Session token'ın doğru oluşturulduğunu kontrol edin
3. Backend loglarında WebSocket bağlantı denemelerini arayın

## Önemli Dosyalar

- **Backend Başlatma**: `backend/START_BACKEND_SIMPLE.bat`
- **Backend Konfigürasyonu**: `backend/app/config.py`
- **Flutter Konfigürasyonu**: `omechat_app/lib/core/config/app_config.dart`
- **API Client**: `omechat_app/lib/services/api_client.dart`
- **WebSocket Client**: `omechat_app/lib/services/websocket_client.dart`

## Test Scriptleri

- **Backend Endpoint Testi**: `backend/test_diagnostic.py`
- **Bağlantı Testi**: `backend/test_flutter_connection.py`

Çalıştırmak için:
```bash
cd backend
python test_flutter_connection.py
```

## Durum

✅ Backend çalışıyor ve erişilebilir
✅ Tüm endpoint'ler test edildi ve çalışıyor
✅ Flutter app konfigürasyonu güncellendi
⏳ Flutter app'ten end-to-end test bekleniyor
