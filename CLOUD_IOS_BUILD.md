# Cloud iOS Build Servisleri - IPA Oluşturma

Windows'ta IPA oluşturmak için cloud-based servisler kullanabilirsiniz:

## 1. Codemagic (ÖNERİLEN - Flutter'a Özel)
🌐 **Website:** https://codemagic.io

### Özellikler:
- ✅ Flutter'a özel tasarlanmış
- ✅ Ücretsiz plan (500 dakika/ay)
- ✅ Otomatik iOS build
- ✅ GitHub/GitLab/Bitbucket entegrasyonu
- ✅ TestFlight otomatik yükleme

### Kullanım:
1. https://codemagic.io adresine gidin
2. GitHub hesabınızla giriş yapın
3. Repository'nizi seçin
4. iOS build yapılandırması yapın
5. Build başlatın
6. IPA dosyasını indirin

---

## 2. AppCircle
🌐 **Website:** https://appcircle.io

### Özellikler:
- ✅ Ücretsiz plan
- ✅ iOS/Android build
- ✅ CI/CD pipeline
- ✅ TestFlight entegrasyonu

---

## 3. Bitrise
🌐 **Website:** https://www.bitrise.io

### Özellikler:
- ✅ Ücretsiz plan (200 build/ay)
- ✅ iOS/Android build
- ✅ Workflow builder
- ✅ TestFlight otomatik yükleme

---

## 4. GitHub Actions (macOS Runner)
🌐 **Website:** https://github.com

### Özellikler:
- ✅ Ücretsiz (public repo)
- ✅ macOS runner kullanır
- ✅ Custom workflow
- ✅ Flutter build action

### Workflow Örneği:
```yaml
name: Build iOS
on: [push]
jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter build ipa
      - uses: actions/upload-artifact@v2
        with:
          name: ipa
          path: build/ios/ipa/*.ipa
```

---

## 5. EAS Build (Expo)
🌐 **Website:** https://expo.dev

### Özellikler:
- ✅ Ücretsiz plan
- ✅ iOS/Android build
- ✅ Flutter desteği (sınırlı)

---

## En Hızlı Çözüm: Codemagic

1. **GitHub'a push edin:**
   ```bash
   git add .
   git commit -m "iOS build ready"
   git push
   ```

2. **Codemagic'e gidin:**
   - https://codemagic.io
   - "Start building" butonuna tıklayın
   - Repository'nizi seçin
   - iOS build yapılandırması yapın
   - Build başlatın

3. **IPA indirin:**
   - Build tamamlandıktan sonra IPA dosyasını indirin

---

## Alternatif: Ücretsiz macOS VM

- **MacinCloud:** https://www.macincloud.com
- **MacStadium:** https://www.macstadium.com
- **AWS EC2 Mac:** https://aws.amazon.com/ec2/instance-types/mac/

Bu servisler ücretli ama saatlik ödeme yapabilirsiniz.

---

## Hızlı Başlangıç - Codemagic

1. Projeyi GitHub'a yükleyin
2. https://codemagic.io → Sign up
3. Repository bağlayın
4. iOS build yapılandırması:
   - Bundle ID: `com.omechat.omechatApp`
   - Team ID: (Apple Developer hesabınızdan)
5. Build başlatın
6. IPA indirin

**Süre:** ~15-20 dakika

