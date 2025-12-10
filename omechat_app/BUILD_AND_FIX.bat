@echo off
setlocal enabledelayedexpansion

echo ========================================
echo BUILD AND FIX - Otomatik Düzeltme
echo ========================================
echo.

cd /d "%~dp0"

:TRY_BUILD
echo.
echo [DENEME !BUILD_ATTEMPT!] Build başlatılıyor...
echo.

call flutter run -d "sdk gphone64 x86 64" 2>&1 | findstr /C:"BUILD FAILED" /C:"FAILURE" /C:"Error" /C:"BUILD SUCCESSFUL" /C:"Built"

if errorlevel 1 (
    echo.
    echo Build tamamlandı, sonuç kontrol ediliyor...
    goto :CHECK_RESULT
) else (
    echo.
    echo Hata tespit edildi, düzeltme deneniyor...
    goto :FIX_ISSUES
)

:FIX_ISSUES
echo.
echo [DÜZELTME] Cache temizleniyor...
if exist "%USERPROFILE%\.gradle\caches\jars-9" (
    rmdir /s /q "%USERPROFILE%\.gradle\caches\jars-9" 2>nul
)
if exist "%USERPROFILE%\.gradle\daemon" (
    rmdir /s /q "%USERPROFILE%\.gradle\daemon" 2>nul
)

echo Cache temizlendi, tekrar deneniyor...
set /a BUILD_ATTEMPT+=1
if !BUILD_ATTEMPT! LSS 5 (
    goto :TRY_BUILD
) else (
    echo.
    echo Maksimum deneme sayısına ulaşıldı!
    goto :END
)

:CHECK_RESULT
echo.
echo Build sonucu kontrol ediliyor...
echo Eğer başarılıysa, işlem tamamlandı!
echo.

:END
pause

