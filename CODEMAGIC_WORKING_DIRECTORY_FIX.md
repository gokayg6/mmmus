# Codemagic Working Directory Hatası - Hızlı Çözüm

## Sorun
"Expected to find project root in current working directory" hatası

## Çözüm (2 Yöntem)

### Yöntem 1: Codemagic UI'da Ayarlama (EN KOLAY)

1. Codemagic'te projenize gidin
2. **Settings** → **Build** sekmesine tıklayın
3. **Working directory** alanını bulun
4. Eğer projeniz `omechat_app` klasöründeyse:
   - **Working directory:** `omechat_app` yazın
5. **Save** butonuna tıklayın
6. Build'i tekrar başlatın

---

### Yöntem 2: codemagic.yaml'ı Güncelleme

Eğer repository yapınız şöyleyse:
```
your-repo/
  └── omechat_app/
      ├── pubspec.yaml
      ├── lib/
      └── codemagic.yaml
```

`codemagic.yaml` dosyasını şöyle güncelleyin:

```yaml
workflows:
  ios-workflow:
    name: iOS Workflow
    max_build_duration: 120
    instance_type: mac_mini_m1
    environment:
      flutter: stable
      xcode: latest
      cocoapods: default
    scripts:
      - name: Get dependencies
        script: |
          cd omechat_app  # ← Bu satırı ekleyin
          flutter pub get
      - name: Build iOS
        script: |
          cd omechat_app  # ← Bu satırı ekleyin
          flutter build ipa --release
    artifacts:
      - omechat_app/build/ios/ipa/*.ipa  # ← Path'i güncelleyin
```

---

## Hangi Yöntemi Kullanmalıyım?

- **Repository root'u `omechat_app` ise:** Yöntem 1 (UI'da ayarlama)
- **Repository root'u üst klasör ise:** Yöntem 2 (yaml güncelleme)

---

## Kontrol

Build başlatmadan önce şunu kontrol edin:
- Working directory'de `pubspec.yaml` dosyası var mı?
- `flutter pub get` komutu çalışıyor mu?

---

## Hızlı Test

Codemagic'te **Test build** yapın:
1. Settings → Build → Working directory: `omechat_app`
2. Save
3. Build başlat
4. "Get dependencies" adımında hata olmamalı

