# 🚀 OmeChat Deployment Rehberi

## Backend Deployment (Railway - Önerilen)

### 1. Railway Hesabı Oluştur
- https://railway.app → GitHub ile giriş yap
- Ücretsiz plan: $5 kredi/ay (yaklaşık 500 saat)

### 2. Proje Oluştur
1. **New Project** > **Deploy from GitHub repo**
2. Repository'yi seç
3. **Backend** klasörünü seç
4. Railway otomatik olarak deploy eder

### 3. PostgreSQL Database Ekle
1. Railway dashboard'da **+ New** > **Database** > **PostgreSQL**
2. Railway otomatik olarak `DATABASE_URL` environment variable'ını ekler

### 4. Environment Variables
Railway dashboard'da **Variables** sekmesine git:

```
DEBUG=False
JWT_SECRET_KEY=your-super-secret-key-change-this-2024
```

**Not:** `DATABASE_URL` otomatik olarak PostgreSQL'den eklenir.

### 5. Domain Al
1. **Settings** > **Generate Domain**
2. Backend URL'inizi alın: `https://your-backend.railway.app`

### 6. Flutter App'i Güncelle
**Dosya:** `omechat_app/lib/core/config/app_config.dart`

```dart
static const String productionBackendUrl = 'https://your-backend.railway.app';
static const bool useProductionBackend = true; // Production'a geç
```

### 7. APK Derle
```bash
cd omechat_app
flutter build apk --release
```

---

## Alternatif: Render.com

### 1. Render Hesabı
- https://render.com → GitHub ile giriş yap
- Ücretsiz plan: 750 saat/ay

### 2. Web Service Oluştur
1. **New** > **Web Service**
2. GitHub repo'yu bağla
3. Ayarlar:
   - **Name:** omechat-backend
   - **Environment:** Python 3
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `uvicorn app.main:app --host 0.0.0.0 --port $PORT`

### 3. PostgreSQL Database
1. **New** > **PostgreSQL**
2. Render otomatik olarak `DATABASE_URL` ekler

### 4. Environment Variables
```
DEBUG=False
JWT_SECRET_KEY=your-secret-key
```

---

## ✅ Deployment Kontrol Listesi

- [ ] Backend Railway/Render'da deploy edildi
- [ ] PostgreSQL database oluşturuldu
- [ ] Environment variables ayarlandı
- [ ] Backend URL test edildi: `https://your-backend.railway.app/`
- [ ] Flutter app'te `app_config.dart` güncellendi
- [ ] `useProductionBackend = true` yapıldı
- [ ] APK yeniden derlendi
- [ ] Test edildi

---

## 🔗 Backend URL Örnekleri

**Railway:**
- `https://omechat-backend-production.up.railway.app`

**Render:**
- `https://omechat-backend.onrender.com`

---

## 📝 Notlar

- **Vercel:** FastAPI için uygun değil (serverless functions için)
- **Railway:** En kolay ve hızlı (önerilen)
- **Render:** Alternatif, ücretsiz tier var
- **Database:** Railway/Render otomatik PostgreSQL sağlar
- **HTTPS:** Otomatik SSL sertifikası (Railway/Render)

