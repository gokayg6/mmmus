# Codemagic YAML Dosyaları - Hangi Dosyayı Kullanmalıyım?

## İki YAML Dosyası Hazırlandı

### 1. `omechat_app/codemagic.yaml`
**Kullanım:** Repository root'u `omechat_app` klasörü ise
- GitHub'da repository root'u `omechat_app` klasörü
- `pubspec.yaml` repository root'unda
- Bu yaml dosyasını kullanın

### 2. `codemagic.yaml` (Ome klasöründe)
**Kullanım:** Repository root'u `Ome` klasörü ise
- GitHub'da repository root'u `Ome` klasörü
- `pubspec.yaml` `omechat_app` alt klasöründe
- Bu yaml dosyasını kullanın (cd komutları var)

---

## Hangi Dosyayı Kullanmalıyım?

### Kontrol:
1. GitHub repository'nize gidin
2. Repository root'unda `pubspec.yaml` var mı?
   - ✅ **VARSA** → `omechat_app/codemagic.yaml` kullanın
   - ❌ **YOKSA** → `codemagic.yaml` (root'taki) kullanın

---

## Alternatif: Codemagic UI'da Ayarlama

Hangi yaml dosyasını kullanırsanız kullanın, Codemagic UI'da:

1. **Settings** → **Build**
2. **Working directory** alanına:
   - Eğer repository root'u `omechat_app` ise: boş bırakın
   - Eğer repository root'u `Ome` ise: `omechat_app` yazın
3. **Save**

---

## Önerilen Yapı

**En kolay çözüm:**
- Repository root'u `omechat_app` klasörü olacak şekilde ayarlayın
- `omechat_app/codemagic.yaml` dosyasını kullanın
- Working directory ayarına gerek yok

---

## Test

Build başlatmadan önce:
- Working directory'de `pubspec.yaml` dosyası olmalı
- `flutter pub get` komutu çalışmalı

