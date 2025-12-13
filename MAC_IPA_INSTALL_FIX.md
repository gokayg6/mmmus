# macOS IPA Kurulum - Hızlı Çözüm

## ❌ Hata: `ios-deploy: command not found`

### ✅ Çözüm 1: ios-deploy Kur (Önerilen)

```bash
# Homebrew ile kur
brew install ios-deploy

# Eğer Homebrew yoksa önce Homebrew kur:
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### ✅ Çözüm 2: npm ile Kur (Alternatif)

```bash
# npm ile kur
npm install -g ios-deploy

# Eğer npm yoksa:
brew install node
```

---

## 🚀 Kurulum Sonrası

### 1. ios-deploy Kuruldu mu Kontrol Et
```bash
ios-deploy --version
```

### 2. Cihazı Bağla ve Güven
- iPhone/iPad'i USB ile Mac'e bağla
- Cihazda "Bu bilgisayara güven" mesajını onayla
- Cihazın kilidini aç

### 3. Cihaz Bağlı mı Kontrol Et
```bash
ios-deploy --detect
```

### 4. IPA'yı Kur
```bash
# Script ile
./install_ipa.sh ~/Downloads/omechat_app.ipa

# Veya direkt
ios-deploy --bundle ~/Downloads/omechat_app.ipa
```

---

## 🔧 Alternatif: ideviceinstaller

Eğer `ios-deploy` çalışmazsa:

```bash
# libimobiledevice kur
brew install libimobiledevice
brew install ideviceinstaller

# Cihaz kontrol
idevice_id -l

# IPA kur
ideviceinstaller -i ~/Downloads/omechat_app.ipa
```

---

## 📝 Güncellenmiş Script

```bash
# Script'i tekrar oluştur (ios-deploy kontrolü ile)
cat > install_ipa.sh << 'EOF'
#!/bin/bash

IPA_PATH="$1"

if [ -z "$IPA_PATH" ]; then
    echo "Kullanım: ./install_ipa.sh <ipa_dosya_yolu>"
    exit 1
fi

# ios-deploy kurulu mu kontrol et
if ! command -v ios-deploy &> /dev/null; then
    echo "❌ ios-deploy bulunamadı!"
    echo "📦 Kurulum için: brew install ios-deploy"
    exit 1
fi

# Cihaz bağlı mı kontrol et
if ! ios-deploy --detect > /dev/null 2>&1; then
    echo "❌ iOS cihaz bulunamadı!"
    echo "📱 Lütfen cihazı bağlayın ve 'Güven' butonuna basın"
    exit 1
fi

echo "📱 Cihaz bulundu, IPA kuruluyor..."
ios-deploy --bundle "$IPA_PATH"

if [ $? -eq 0 ]; then
    echo "✅ Kurulum başarılı!"
else
    echo "❌ Kurulum başarısız!"
    exit 1
fi
EOF

chmod +x install_ipa.sh
```

---

## ⚡ Tek Komutla Her Şey

```bash
# Homebrew yoksa kur
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# ios-deploy kur
brew install ios-deploy

# Cihazı bağla ve güven

# IPA kur
ios-deploy --bundle ~/Downloads/omechat_app.ipa
```

---

## 🎯 Hızlı Test

```bash
# 1. ios-deploy var mı?
ios-deploy --version

# 2. Cihaz bağlı mı?
ios-deploy --detect

# 3. IPA kur
ios-deploy --bundle ~/Downloads/omechat_app.ipa
```

