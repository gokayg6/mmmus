# Codemagic Code Signing Skip - Hızlı Kurulum

## ✅ YAML Dosyaları Hazır

YAML dosyaları test için code signing olmadan çalışacak şekilde ayarlandı.

## 🔧 Codemagic UI'da Yapılacaklar

### Adım 1: Codemagic'te Projenize Gidin
1. Codemagic web sitesine giriş yapın
2. Projenizi seçin

### Adım 2: Code Signing'i Skip Edin
1. **Settings** → **Code signing** sekmesine gidin
2. **Skip code signing** seçeneğini işaretleyin ✅
3. **Save** butonuna tıklayın

### Adım 3: Build Başlatın
1. **Start new build** butonuna tıklayın
2. **ios-workflow** workflow'unu seçin
3. Build başlatın

---

## ⚠️ Önemli Notlar

- ✅ **IPA dosyası oluşacak** ama cihaza kurulamaz (sadece test için)
- ✅ **Build başarılı olacak** code signing hatası olmayacak
- ❌ **Cihaza kurulum için** Apple Developer hesabı ve code signing gerekli

---

## 📱 Production İçin (Cihaza Kurulum)

Eğer gerçek cihaza kurmak istiyorsanız:

1. **Apple Developer hesabı oluşturun:**
   - https://developer.apple.com
   - Ücretsiz veya ücretli ($99/yıl)

2. **Codemagic'te credentials ekleyin:**
   - Settings → Code signing identities
   - Apple ID ile giriş yapın
   - Sertifikalar otomatik oluşturulacak

3. **YAML'ı güncelleyin:**
   - `groups: - app_store_credentials` satırının yorumunu kaldırın
   - Credentials group adını yazın

4. **Skip code signing'i kaldırın:**
   - Settings → Code signing
   - Skip code signing seçeneğini kaldırın

5. **Build başlatın**

---

## 🚀 Hızlı Test

1. Codemagic UI'da **Skip code signing** işaretle
2. Build başlat
3. IPA dosyasını indir (test için)

**Hazır!** 🎉

