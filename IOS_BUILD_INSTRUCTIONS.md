# iOS IPA Build Talimatları

## Önemli Not
Windows'ta doğrudan IPA oluşturulamaz. iOS build için **macOS** ve **Xcode** gereklidir.

## Gereksinimler
1. macOS bilgisayar veya Mac
2. Xcode (App Store'dan indirilebilir)
3. Apple Developer hesabı (ücretsiz veya ücretli)

## Build Adımları

### 1. macOS'ta Projeyi Açın
```bash
cd /path/to/Ome/omechat_app
open ios/Runner.xcworkspace
```

### 2. Xcode'da Yapılandırma
- **Signing & Capabilities** sekmesine gidin
- **Team** seçin (Apple Developer hesabınız)
- **Bundle Identifier** ayarlayın (örn: `com.omechat.app`)

### 3. IPA Oluşturma

#### Terminal'den:
```bash
cd /path/to/Ome/omechat_app
flutter build ipa
```

#### Xcode'dan:
1. **Product** → **Archive**
2. Archive tamamlandıktan sonra **Distribute App**
3. **Ad Hoc** veya **App Store** seçin
4. IPA dosyası oluşturulacak

## IPA Dosya Konumu
```
omechat_app/build/ios/ipa/OmeChat.ipa
```

## Alternatif: TestFlight
1. App Store Connect'e giriş yapın
2. Uygulamayı yükleyin
3. TestFlight ile beta test yapın

## İzinler
Info.plist dosyasına şu izinler eklendi:
- ✅ NSCameraUsageDescription
- ✅ NSMicrophoneUsageDescription
- ✅ NSPhotoLibraryUsageDescription

## Not
Windows'ta sadece Android APK oluşturulabilir. iOS için macOS gereklidir.

