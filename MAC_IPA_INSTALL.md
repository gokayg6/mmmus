# macOS Terminal - IPA Kurulum Komutları

## 📱 Gerçek iPhone/iPad'e Kurulum

### Yöntem 1: ios-deploy (Önerilen)

#### 1. ios-deploy Kurulumu
```bash
# Homebrew ile kurulum
brew install ios-deploy

# Veya npm ile
npm install -g ios-deploy
```

#### 2. Cihazı Bağlayın ve Güvenin
1. iPhone/iPad'i USB ile Mac'e bağlayın
2. Cihazda "Bu bilgisayara güven" mesajını onaylayın
3. Cihazın kilidini açın

#### 3. IPA'yı Kurun
```bash
# IPA dosyasının yolunu belirtin
ios-deploy --bundle /path/to/your/app.ipa

# Örnek (Codemagic'ten indirdiyseniz):
ios-deploy --bundle ~/Downloads/omechat_app.ipa

# Veya mevcut dizinde ise:
ios-deploy --bundle ./omechat_app.ipa
```

#### 4. Cihazı Kontrol Edin
```bash
# Bağlı cihazları listele
ios-deploy --detect

# Cihaz bilgilerini göster
idevice_id -l
```

---

### Yöntem 2: ideviceinstaller (Alternatif)

#### 1. libimobiledevice Kurulumu
```bash
brew install libimobiledevice
brew install ideviceinstaller
```

#### 2. IPA'yı Kurun
```bash
# Cihazı kontrol et
idevice_id -l

# IPA'yı kur
ideviceinstaller -i /path/to/your/app.ipa

# Örnek:
ideviceinstaller -i ~/Downloads/omechat_app.ipa
```

---

## 🖥️ iOS Simulator'e Kurulum

### 1. Simulator'ü Başlatın
```bash
# Simulator'ü aç
open -a Simulator

# Veya belirli bir cihaz ile
xcrun simctl boot "iPhone 15 Pro"
```

### 2. IPA'yı Simulator'e Kurun
```bash
# IPA'yı extract et ve .app dosyasını bul
unzip -q /path/to/your/app.ipa -d /tmp/ipa_extract

# .app dosyasını simulator'e kur
xcrun simctl install booted /tmp/ipa_extract/Payload/*.app

# Örnek:
unzip -q ~/Downloads/omechat_app.ipa -d /tmp/ipa_extract
xcrun simctl install booted /tmp/ipa_extract/Payload/*.app

# Temizlik
rm -rf /tmp/ipa_extract
```

### 3. Simulator'de Çalıştırın
```bash
# Uygulamayı başlat (Bundle ID ile)
xcrun simctl launch booted com.omechat.omechatApp

# Veya bundle path ile
xcrun simctl launch booted /tmp/ipa_extract/Payload/*.app
```

---

## 🔧 Hızlı Kurulum Scripti

### Tek Komutla Kurulum (Gerçek Cihaz)
```bash
# Script oluştur
cat > install_ipa.sh << 'EOF'
#!/bin/bash

if [ -z "$1" ]; then
    echo "Kullanım: ./install_ipa.sh <ipa_dosya_yolu>"
    exit 1
fi

IPA_PATH="$1"

if [ ! -f "$IPA_PATH" ]; then
    echo "Hata: IPA dosyası bulunamadı: $IPA_PATH"
    exit 1
fi

echo "Cihaz kontrol ediliyor..."
if ! ios-deploy --detect > /dev/null 2>&1; then
    echo "Hata: iOS cihaz bulunamadı. Lütfen cihazı bağlayın ve güvenin."
    exit 1
fi

echo "IPA kuruluyor: $IPA_PATH"
ios-deploy --bundle "$IPA_PATH"

if [ $? -eq 0 ]; then
    echo "✅ Kurulum başarılı!"
else
    echo "❌ Kurulum başarısız!"
    exit 1
fi
EOF

# Script'i çalıştırılabilir yap
chmod +x install_ipa.sh

# Kullanım:
./install_ipa.sh ~/Downloads/omechat_app.ipa
```

---

## 📋 Kod İmzalama Gerekliyse

### Development Certificate ile İmzalama
```bash
# Mevcut sertifikaları listele
security find-identity -v -p codesigning

# IPA'yı imzala (Development)
codesign --force --sign "iPhone Developer: Your Name (XXXXXXXXXX)" \
    --entitlements entitlements.plist \
    /path/to/your/app.ipa

# Veya Xcode ile
xcodebuild -exportArchive \
    -archivePath /path/to/archive.xcarchive \
    -exportPath ./export \
    -exportOptionsPlist ExportOptions.plist
```

---

## 🚨 Hata Çözümleri

### "No devices found"
```bash
# Cihazı kontrol et
idevice_id -l

# USB bağlantısını kontrol et
system_profiler SPUSBDataType | grep -i iphone

# Trust durumunu kontrol et (cihazda "Güven" butonuna bas)
```

### "Could not find Developer Disk Image"
```bash
# Xcode Command Line Tools güncelle
xcode-select --install

# Xcode'u güncelle
softwareupdate --list
```

### "Code signing is required"
```bash
# IPA'yı extract et
unzip -q app.ipa -d /tmp/ipa_extract

# .app içindeki executable'ı imzala
codesign --force --sign "iPhone Developer: Your Name" \
    /tmp/ipa_extract/Payload/*.app

# Tekrar paketle
cd /tmp/ipa_extract
zip -r ../app_signed.ipa Payload/
```

---

## ✅ Hızlı Test Komutları

```bash
# 1. Cihaz bağlı mı?
ios-deploy --detect

# 2. IPA dosyası var mı?
ls -lh ~/Downloads/*.ipa

# 3. Kurulum (tek komut)
ios-deploy --bundle ~/Downloads/omechat_app.ipa

# 4. Uygulamayı başlat
ios-deploy --bundle ~/Downloads/omechat_app.ipa --justlaunch
```

---

## 📝 Özet - En Hızlı Yöntem

```bash
# 1. ios-deploy kur
brew install ios-deploy

# 2. Cihazı bağla ve güven

# 3. IPA'yı kur
ios-deploy --bundle ~/Downloads/omechat_app.ipa
```

**Hazır!** 🎉

