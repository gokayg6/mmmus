# Codemagic Build Hatası Düzeltme

## Sorun
"Expected to find project root in current working directory" hatası

## Çözüm

### 1. Repository Yapısı Kontrolü
Codemagic, Flutter projesinin root dizininde `pubspec.yaml` dosyasını arar.

**Doğru yapı:**
```
your-repo/
  ├── pubspec.yaml          ← Flutter proje root'u burada olmalı
  ├── lib/
  ├── ios/
  ├── android/
  └── codemagic.yaml
```

**Yanlış yapı:**
```
your-repo/
  └── omechat_app/          ← Bu klasör içinde pubspec.yaml var
      ├── pubspec.yaml
      ├── lib/
      └── ...
```

### 2. Çözüm Seçenekleri

#### Seçenek A: Repository Root'unu Değiştirin (ÖNERİLEN)
Codemagic'te:
1. **Settings** → **Build** → **Working directory**
2. `omechat_app` yazın
3. Kaydedin

#### Seçenek B: codemagic.yaml'ı Düzeltin
```yaml
workflows:
  ios-workflow:
    scripts:
      - name: Get dependencies
        script: |
          cd omechat_app  # Eğer proje alt klasördeyse
          flutter pub get
      - name: Build iOS
        script: |
          cd omechat_app
          flutter build ipa --release
```

#### Seçenek C: Repository Yapısını Değiştirin
GitHub'da repository root'u `omechat_app` klasörü olacak şekilde ayarlayın.

### 3. Hızlı Düzeltme

Codemagic'te:
1. **Settings** → **Build**
2. **Working directory** alanına: `omechat_app` yazın
3. **Save** butonuna tıklayın
4. Build'i tekrar başlatın

---

## Kontrol Listesi

- ✅ `pubspec.yaml` dosyası working directory'de var mı?
- ✅ `codemagic.yaml` dosyası doğru yerde mi?
- ✅ Working directory ayarı doğru mu?

---

## Test
Build başlatmadan önce:
```bash
# Working directory'de şu komut çalışmalı:
flutter pub get
```

Eğer çalışmıyorsa, working directory yanlış demektir.

