@echo off
title Compilatore APK RunVoice
echo ===================================================
echo [RunVoice] Avvio compilazione APK in corso...
echo ===================================================
echo.

:: Si sposta sul disco C e nella cartella corretta
cd /d "C:\Users\rf199\Progetti\[04] RunVoice\run_voice"

:: Esegue la compilazione nativa di Flutter
call flutter build apk --release

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ===================================================
    echo [ERRORE] La compilazione e fallita!
    echo ===================================================
    echo.
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ===================================================
echo [SUCCESSO] APK generato con successo!
echo.
echo Il file APK si trova qui:
echo C:\Users\rf199\Progetti\[04] RunVoice\run_voice\build\app\outputs\flutter-apk\app-release.apk
echo ===================================================
echo.
pause
