# ✅ Kurulum Tamamlandı!

## Yapılan Değişiklikler

1. ✅ API URL yapılandırması güncellendi
2. ✅ WebSocket bağlantısı API client ile senkronize edildi
3. ✅ Platform detection eklendi (otomatik emulator/gerçek cihaz algılama)

## Şimdi Yapmanız Gerekenler

### 1. PC IP Adresinizi Bulun ve Ayarlayın

**Yöntem 1: Otomatik (Önerilen)**
```bash
cd omechat_app
FIND_AND_SET_IP.bat
```
Bu script IP'nizi bulup otomatik ayarlayacak.

**Yöntem 2: Manuel**
1. PowerShell'de: `ipconfig`
2. "IPv4 Address" değerini bulun (örn: `192.168.1.103`)
3. `lib/services/api_client.dart` dosyasını açın
4. Satır 207'deki IP'yi değiştirin:
   ```dart
   return 'http://192.168.1.103:8000';  // IP'nizi buraya yazın
   ```

### 2. Backend'i Başlatın

```bash
cd backend
venv\Scripts\activate
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Backend `http://0.0.0.0:8000` adresinde çalışmalı.

### 3. Firewall Kontrolü

Windows Firewall'da port 8000'i açmanız gerekebilir:
```powershell
New-NetFirewallRule -DisplayName "OmeChat Backend" -Direction Inbound -LocalPort 8000 -Protocol TCP -Action Allow
```

### 4. Uygulamayı Derleyin ve Çalıştırın

```bash
cd omechat_app
flutter clean
flutter pub get
flutter run
```

## Test

1. ✅ Backend çalışıyor mu? → http://localhost:8000 açın, "status":"running" görmelisiniz
2. ✅ İki telefon aynı Wi-Fi ağında mı?
3. ✅ Her iki telefonda da uygulama açıldığında online sayısı artmalı
4. ✅ Kuyruğa giren kullanıcılar otomatik eşleşmeli

## Sorun Giderme

### "0 çevrimiçi" görünüyorsa:

1. ✅ Backend çalışıyor mu? → Terminal'de backend loglarını kontrol edin
2. ✅ PC IP doğru mu? → `lib/services/api_client.dart` dosyasını kontrol edin
3. ✅ Telefonlar aynı Wi-Fi'de mi?
4. ✅ Firewall port 8000'i engelliyor mu?
5. ✅ Flutter console'da hata var mı? → API Log ve WS Log mesajlarını kontrol edin

### Debug

Flutter console'da görmeniz gerekenler:
- `API Base URL: http://...` → IP doğru görünmeli
- `API Log: ...` → API istekleri
- `WS Connecting to: ...` → WebSocket bağlantıları
- `WS Received: ...` → Gelen mesajlar

Backend console'da:
- Session oluşturma logları
- WebSocket bağlantı logları
- Matchmaking logları

## Notlar

- Android Emulator kullanıyorsanız: `10.0.2.2` IP'sini kullanın
- Gerçek telefonlar için: PC'nizin yerel IP adresini kullanın
- Her iki telefon da aynı Wi-Fi ağında olmalı

Sorun olursa `BACKEND_SETUP.md` dosyasına bakın!



