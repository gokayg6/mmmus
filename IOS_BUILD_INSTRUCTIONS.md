# iOS Build Talimatları (Omechat)

> [!WARNING]
> **Windows Kullanıcıları İçin Önemli Uyarı:**
> iOS uygulamaları (.ipa dosyaları) **sadece macOS** işletim sistemine sahip bir bilgisayarda (MacBook, Mac Mini, vb.) derlenebilir. Windows üzerinde doğrudan iOS build alamazsınız.

Eğer bir Mac bilgisayarınız yoksa, **Codemagic** veya **Bitrise** gibi bulut (cloud) servislerini kullanmanız gerekir.

---

## 🏗️ Seçenek 1: Mac Bilgisayar Kullanarak Build Alma

Eğer elinizde veya erişiminizde bir Mac varsa, projeyi oraya taşıyıp şu adımları izleyin:

### 1. Hazırlık
Mac bilgisayarda şunların kurulu olduğundan emin olun:
- **Xcode** (App Store'dan indirin)
- **Flutter SDK**
- **CocoaPods** (`sudo gem install cocoapods`)

### 2. Projeyi Hazırlama
Projeyi Mac'e indirdikten sonra terminali açın ve proje klasörüne gidin:

```bash
# Bağımlılıkları yükleyin
flutter pub get

# iOS klasörüne gidip pod'ları yükleyin
cd ios
pod install
cd ..
```

### 3. İmzalamayı Ayarlama (Signing)
1.  Terminalde `open ios/Runner.xcworkspace` komutuyla projeyi Xcode'da açın.
2.  Sol menüden **Runner** (en üstteki mavi ikon) seçin.
3.  **Signing & Capabilities** sekmesine gelin.
4.  **Team** kısmından Apple Developer hesabınızı seçin (Hesabınız yoksa kişisel Apple ID'nizle giriş yapın).
5.  **Bundle Identifier**'ın `com.gokay.omechat` (veya belirlediğiniz ID) olduğundan emin olun.

### 4. Build Alma (Arşivleme)
Uygulamayı App Store'a yüklemek veya .ipa dosyası oluşturmak için:

```bash
# Terminalde proje ana dizininde:
flutter build ipa --release
```
*Bu işlem bittiğinde `.ipa` dosyanız `build/ios/archive/Runner.xcarchive` yolunda olacaktır.*

---

## ☁️ Seçenek 2: Bulut Servisleri (Mac'iniz Yoksa)

Windows kullanıyorsanız en iyi çözüm **Codemagic** kullanmaktır.

### Adım Adım Codemagic Kurulumu:

1.  Projenizi **GitHub**'a yükleyin (Zaten yaptınız).
2.  **[codemagic.io](https://codemagic.io)** adresine gidin ve GitHub ile giriş yapın.
3.  "Add Application" diyerek **mmmus** (projenizin adı) reposunu seçin.
4.  **Flutter App** olarak yapılandırın.
5.  **Build for platforms** kısmında **iOS**'u seçin.
6.  **Start Build** butonuna basın.

Codemagic, sanal bir Mac makinesi kiralayarak sizin yerinize build alacak ve işlem bitince size indirilebilir bir **.ipa** dosyası verecektir.

> [!NOTE]
> Codemagic'in ücretsiz planı (Free Tier) genellikle aylık 500 dakika derleme süresi verir, bu da denemeler için yeterlidir.

---

## 🛠️ iOS İçin Özel Ayarlar (Kontrol Listesi)

Projeyi Mac'e veya Cloud'a göndermeden önce şu dosyaların doğru olduğundan emin olun:

### 1. `Info.plist` İzinleri
`ios/Runner/Info.plist` dosyasında şu izinlerin olduğundan emin olun (Video sohbet için şarttır):

```xml
<key>NSCameraUsageDescription</key>
<string>Görüntülü sohbet için kameranıza ihtiyacımız var.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Sesli sohbet için mikrofonunuza ihtiyacımız var.</string>
```

### 2. Minimum iOS Sürümü
`ios/Podfile` dosyasının en üstündeki satırı kontrol edin. Genellikle 11.0 veya 12.0 olmalıdır:

```ruby
platform :ios, '12.0'
```
