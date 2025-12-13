# Codemagic Code Signing Kurulumu

## Sorun
"No valid code signing certificates were found" hatası

## Çözüm: Codemagic'te Code Signing Ayarlama

### Adım 1: Apple Developer Hesabı Bilgilerini Codemagic'e Ekleyin

1. **Codemagic'te projenize gidin**
2. **Settings** → **Code signing identities** sekmesine tıklayın
3. **Add credentials** butonuna tıklayın
4. **Apple ID** ile giriş yapın (Apple Developer hesabınız)
5. Codemagic otomatik olarak sertifikaları oluşturacak

---

### Adım 2: Code Signing Yapılandırması

Codemagic'te:
1. **Settings** → **Code signing identities**
2. **iOS distribution certificate** oluşturun
3. **iOS provisioning profile** oluşturun
4. **Bundle ID:** `com.omechat.omechatApp`
5. **Team ID:** (Apple Developer hesabınızdan alın)

---

### Adım 3: YAML'da Credentials Group Ekleme

`codemagic.yaml` dosyasında `groups` ekleyin:

```yaml
environment:
  groups:
    - app_store_credentials  # Codemagic'te oluşturduğunuz credentials group adı
```

---

### Adım 4: Alternatif - TestFlight İçin (Ad Hoc)

Eğer sadece test için IPA istiyorsanız:

```yaml
scripts:
  - name: Build iOS (Ad Hoc - No Code Signing)
    script: |
      flutter build ipa --release \
        --build-name=1.0.0 \
        --build-number=1 \
        --export-method=ad-hoc
```

---

## Hızlı Çözüm (Test İçin)

Eğer sadece IPA dosyasını test etmek istiyorsanız:

1. Codemagic'te **Settings** → **Code signing**
2. **Skip code signing** seçeneğini işaretleyin (sadece test için)
3. Build başlatın
4. IPA dosyası oluşacak ama cihaza kurulamaz (sadece test için)

---

## Tam Çözüm (Production)

1. **Apple Developer hesabı oluşturun:**
   - https://developer.apple.com
   - Ücretsiz veya ücretli ($99/yıl)

2. **Codemagic'te credentials ekleyin:**
   - Settings → Code signing identities
   - Apple ID ile giriş yapın
   - Sertifikalar otomatik oluşturulacak

3. **YAML'ı güncelleyin:**
   - `groups: - app_store_credentials` ekleyin

4. **Build başlatın**

---

## Önemli Notlar

- ✅ **Ücretsiz Apple Developer hesabı:** Test için yeterli
- ✅ **Ücretli Apple Developer hesabı ($99/yıl):** App Store'a yükleme için
- ⚠️ **Code signing olmadan:** IPA oluşur ama cihaza kurulamaz
- ✅ **Codemagic otomatik:** Sertifikaları otomatik oluşturur

---

## Test İçin Hızlı Yol

1. Codemagic'te **Settings** → **Code signing**
2. **Skip code signing** seçin
3. Build başlatın
4. IPA dosyasını indirin (test için)

