# 🧪 Test Rehberi - Telefonların Birbirini Bulması

## ✅ Backend Durumu
Backend başarıyla çalışıyor! `http://0.0.0.0:8000` adresinde aktif.

## 📱 Test Adımları

### 1. Flutter Uygulamasını Çalıştırın

**Terminal 1'de (Backend zaten çalışıyor):**
- Backend çalışıyor, bırakın açık kalsın

**Terminal 2'de:**
```bash
cd omechat_app
flutter run
```

VEYA telefonlarınızda zaten uygulama yüklüyse:
- Her iki telefonda da uygulamayı açın
- Matchmaking ekranına girin

### 2. Beklenen Davranış

**İlk Telefon Açıldığında:**
- Backend console'da: `WebSocket connection accepted`
- Telefon ekranında: `Online: 1` görünmeli

**İkinci Telefon Açıldığında:**
- Backend console'da: Yeni `WebSocket connection accepted`
- Her iki telefonda da: `Online: 2` görünmeli
- İkinci telefon kuyruğa girdiğinde: Otomatik eşleşme olmalı!

### 3. Backend Console'da İzlenecekler

✅ **Başarılı Bağlantı:**
```
WebSocket connection accepted
JOIN_QUEUE message received
MATCH_FOUND - Connection established
```

❌ **Sorun Varsa:**
```
Invalid session
Connection refused
WebSocket error
```

### 4. Flutter Console'da İzlenecekler

✅ **Başarılı Bağlantı:**
```
API Base URL: http://192.168.1.103:8000
WS Connecting to: ws://192.168.1.103:8000/ws/signaling?session_token=...
WS Received: {"type":"QUEUE_POSITION","position":1,"online_count":2}
```

❌ **Sorun Varsa:**
```
Failed to connect
Connection timeout
WebSocket error
```

## 🔍 Sorun Giderme

### "0 çevrimiçi" Görünüyorsa

1. ✅ **Backend çalışıyor mu?**
   - Terminal'de backend logları görünüyor mu?
   - http://localhost:8000/api/v1/public/health açılıyor mu?

2. ✅ **WebSocket bağlantısı kuruluyor mu?**
   - Backend console'da `WebSocket connection accepted` görünüyor mu?
   - Flutter console'da `WS Connecting to: ...` görünüyor mu?

3. ✅ **IP adresi doğru mu?**
   - `lib/services/api_client.dart` dosyasında IP `192.168.1.103` olmalı
   - Her iki telefon da PC ile aynı Wi-Fi ağında olmalı

4. ✅ **Firewall engelliyor mu?**
   - Windows Firewall port 8000'i açık olmalı
   - Router ayarları kontrol edilmeli

### WebSocket Bağlantı Hataları

**"Invalid session" hatası:**
- Session token geçersiz veya süresi dolmuş
- Uygulamayı kapatıp yeniden açın

**"Connection refused" hatası:**
- IP adresi yanlış
- Backend çalışmıyor
- Firewall engelliyor

**"Connection timeout" hatası:**
- Telefonlar PC ile aynı ağda değil
- IP adresi yanlış

## 📊 Başarı Kriterleri

✅ Her iki telefonda da `Online: 2` görünüyor
✅ Backend console'da her iki telefon için `WebSocket connection accepted` var
✅ İkinci telefon kuyruğa girdiğinde otomatik eşleşme oluyor
✅ Chat ekranına geçiş yapılıyor

## 🎯 Sonraki Adımlar

Eğer telefonlar birbirini buluyorsa:
1. ✅ Video sohbet test edilmeli
2. ✅ Chat mesajlaşma test edilmeli
3. ✅ "Next" butonu test edilmeli
4. ✅ Disconnect durumları test edilmeli

Sorun varsa backend ve Flutter console loglarını paylaşın!



