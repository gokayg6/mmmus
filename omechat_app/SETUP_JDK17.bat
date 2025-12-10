@echo off
echo ========================================
echo JDK 17 Kurulum ve Ayarlama Scripti
echo ========================================
echo.

echo Android Studio mevcut JDK: JDK 21 (Java 17 ile uyumlu)
echo Bu JDK zaten gradle.properties dosyasına eklendi.
echo.

echo Şimdi Gradle cache temizleniyor...
if exist "%USERPROFILE%\.gradle\caches\transforms-3" (
    rmdir /s /q "%USERPROFILE%\.gradle\caches\transforms-3"
    echo Gradle transforms cache temizlendi!
)

if exist "%USERPROFILE%\.gradle\caches\modules-2\files-2.1" (
    rmdir /s /q "%USERPROFILE%\.gradle\caches\modules-2\files-2.1"
    echo Gradle modules cache temizlendi!
)

echo.
echo ========================================
echo YAPILANDIRMA TAMAMLANDI!
echo ========================================
echo.
echo Android Studio JDK 21 kullanıyor (Java 17 uyumlu)
echo Bu ayar gradle.properties dosyasına eklendi.
echo.
echo Şimdi projeyi derleyebilirsiniz:
echo   flutter clean
echo   flutter pub get
echo   flutter run
echo.
pause

