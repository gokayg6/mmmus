# 🚀 Railway'de Backend Deployment Rehberi

## Hızlı Başlangıç

### 1. Railway Hesabı Oluştur
- https://railway.app adresine git
- GitHub ile giriş yap (ücretsiz)

### 2. Yeni Proje Oluştur
- "New Project" > "Deploy from GitHub repo"
- Bu repository'yi seç
- Backend klasörünü seç

### 3. Environment Variables (Ortam Değişkenleri)
Railway dashboard'da **Variables** sekmesine git ve şunları ekle:

```
DATABASE_URL=postgresql://postgres:password@postgres.railway.internal:5432/railway
DEBUG=False
JWT_SECRET_KEY=your-super-secret-key-change-this-2024
```

**Not:** Railway otomatik olarak PostgreSQL database oluşturur ve `DATABASE_URL` environment variable'ını ekler.

### 4. PostgreSQL Database Ekle
- Railway dashboard'da **+ New** > **Database** > **PostgreSQL**
- Railway otomatik olarak `DATABASE_URL` environment variable'ını ekler

### 5. Deploy
- Railway otomatik olarak deploy eder
- Deploy tamamlandığında **Settings** > **Generate Domain** ile public URL al

## 🔧 Alternatif: Render.com

### 1. Render Hesabı
- https://render.com adresine git
- GitHub ile giriş yap

### 2. Yeni Web Service
- **New** > **Web Service**
- GitHub repo'yu bağla
- Ayarlar:
  - **Name:** omechat-backend
  - **Environment:** Python 3
  - **Build Command:** `pip install -r requirements.txt`
  - **Start Command:** `uvicorn app.main:app --host 0.0.0.0 --port $PORT`

### 3. Environment Variables
```
DATABASE_URL=postgresql://... (Render PostgreSQL'den al)
DEBUG=False
JWT_SECRET_KEY=your-secret-key
```

### 4. PostgreSQL Database
- **New** > **PostgreSQL**
- Render otomatik olarak `DATABASE_URL` ekler

## 📱 Flutter App'te Backend URL'ini Güncelle

Deploy edilen backend URL'ini Flutter app'te güncelle:

**Dosya:** `omechat_app/lib/core/config/app_config.dart`

```dart
// Production backend URL (Railway/Render'dan al)
static const String productionBackendUrl = 'https://your-backend.railway.app';

// Production kullanmak için:
static const bool useProductionBackend = true;
```

**Not:** Artık tüm servisler (API, Admin, Features) otomatik olarak bu URL'i kullanacak!

## ✅ Deployment Sonrası Kontrol

1. Backend URL'ini test et: `https://your-backend.railway.app/`
2. API test: `https://your-backend.railway.app/api/v1/auth/register`
3. Flutter app'te backend URL'ini güncelle
4. Admin panel: `https://your-backend.railway.app/api/v1/admin/auth/login`

## 🎯 Önerilen Platform: Railway

**Neden Railway?**
- ✅ Ücretsiz tier (500 saat/ay)
- ✅ Otomatik PostgreSQL
- ✅ Kolay deployment
- ✅ GitHub entegrasyonu
- ✅ Environment variables yönetimi
- ✅ Log görüntüleme

**Railway Ücretsiz Plan:**
- $5 kredi/ay (yaklaşık 500 saat)
- PostgreSQL dahil
- Unlimited deployments

