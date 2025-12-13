# 🚀 iOS IPA Oluşturma - Hızlı Başlangıç

## En Kolay Yöntem: Codemagic (ÖNERİLEN)

### Adımlar:

1. **GitHub'a Push Edin:**
   ```bash
   cd C:\Users\gokay\Desktop\Ome\omechat_app
   git init
   git add .
   git commit -m "iOS build ready"
   git remote add origin YOUR_GITHUB_REPO_URL
   git push -u origin main
   ```

2. **Codemagic'e Gidin:**
   - 🌐 https://codemagic.io
   - "Start building for free" butonuna tıklayın
   - GitHub hesabınızla giriş yapın
   - Repository'nizi seçin (`omechat_app`)

3. **iOS Build Yapılandırması:**
   - **Workflow:** iOS
   - **Bundle ID:** `com.omechat.omechatApp`
   - **Team ID:** (Apple Developer hesabınızdan alın)
   - **Certificate:** Otomatik oluşturulacak

4. **Build Başlatın:**
   - "Start new build" butonuna tıklayın
   - Build ~15-20 dakika sürecek

5. **IPA İndirin:**
   - Build tamamlandıktan sonra "Download" butonuna tıklayın
   - IPA dosyası indirilecek

---

## Alternatif: GitHub Actions

1. **Repository'yi GitHub'a push edin**
2. **Actions** sekmesine gidin
3. **iOS Build** workflow'unu çalıştırın
4. IPA dosyasını **Artifacts** bölümünden indirin

---

## Diğer Servisler:

- **AppCircle:** https://appcircle.io
- **Bitrise:** https://www.bitrise.io
- **EAS Build:** https://expo.dev

---

## Önemli Notlar:

- ✅ Codemagic yapılandırma dosyası hazır: `omechat_app/codemagic.yaml`
- ✅ GitHub Actions workflow hazır: `.github/workflows/ios.yml`
- ✅ iOS izinleri Info.plist'e eklendi
- ⚠️ Apple Developer hesabı gereklidir (ücretsiz veya ücretli)

---

## Hızlı Başlangıç:

1. Projeyi GitHub'a yükleyin
2. https://codemagic.io → Sign up
3. Repository bağlayın
4. Build başlatın
5. IPA indirin

**Toplam süre:** ~20 dakika

