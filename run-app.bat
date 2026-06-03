@echo off
echo ========================================
echo Customer App - Quick Start
echo ========================================
echo.

cd /d "%~dp0"

echo [1/3] Cleaning previous builds...
call flutter clean

echo.
echo [2/3] Getting dependencies...
call flutter pub get

echo.
echo [3/3] Running app...
call flutter run

pause
