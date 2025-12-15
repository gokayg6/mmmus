# iOS App Icon Güncelleme Talimatları

## Manuel Yöntem (Önerilen)

1. **Logo dosyasını hazırlayın:**
   - `assets/images/logo.png` dosyasını kullanın
   - 1024x1024 piksel PNG formatında olmalı

2. **Xcode'da güncelleyin:**
   - Xcode'u açın: `open ios/Runner.xcworkspace`
   - Sol panelde `Runner` → `Assets.xcassets` → `AppIcon` seçin
   - Her boyuttaki icon'u logo.png'den oluşturun
   - Veya online tool kullanın: https://www.appicon.co

3. **Online Tool ile (Hızlı):**
   - https://www.appicon.co adresine gidin
   - `assets/images/logo.png` dosyasını yükleyin
   - iOS seçin
   - İndirilen icon'ları `ios/Runner/Assets.xcassets/AppIcon.appiconset/` klasörüne kopyalayın

## Otomatik Yöntem (Flutter Package)

```bash
flutter pub add flutter_launcher_icons
```

`pubspec.yaml`'a ekleyin:
```yaml
flutter_launcher_icons:
  ios: true
  image_path: "assets/images/logo.png"
```

Sonra:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```


