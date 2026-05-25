#!/usr/bin/env pwsh
# setup.ps1 — One-time Flutter project setup for Biomech Coach
# Run this AFTER installing Flutter SDK: https://docs.flutter.dev/get-started/install/windows

Write-Host "=== Biomech Coach — Flutter Project Setup ===" -ForegroundColor Cyan
Write-Host ""

# 1. Verify Flutter is available
try {
    $flutterVersion = flutter --version 2>&1
    Write-Host "[✓] Flutter found." -ForegroundColor Green
} catch {
    Write-Host "[✗] Flutter not found. Please install Flutter first:" -ForegroundColor Red
    Write-Host "    https://docs.flutter.dev/get-started/install/windows" -ForegroundColor Yellow
    exit 1
}

# 2. Check if this is already a Flutter project
$isExistingProject = Test-Path ".\lib\main.dart"
if (-not $isExistingProject) {
    Write-Host "[!] lib/main.dart not found. Running flutter create to scaffold..." -ForegroundColor Yellow
    flutter create . --org com.biomechcoach --project-name biomech_coach --platforms ios,android
    Write-Host "[✓] Flutter project scaffolded." -ForegroundColor Green
} else {
    Write-Host "[✓] Flutter project already scaffolded." -ForegroundColor Green
}

# 3. Create assets directory
if (-not (Test-Path ".\assets\images")) {
    New-Item -ItemType Directory -Path ".\assets\images" -Force | Out-Null
    Write-Host "[✓] Created assets/images directory." -ForegroundColor Green
}

# 4. Install dependencies
Write-Host ""
Write-Host "Installing Flutter dependencies..." -ForegroundColor Cyan
flutter pub get
Write-Host "[✓] Dependencies installed." -ForegroundColor Green

# 5. Run flutter doctor
Write-Host ""
Write-Host "Running flutter doctor..." -ForegroundColor Cyan
flutter doctor

# 6. Summary
Write-Host ""
Write-Host "=== Setup Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  • Android:  Connect a device or start an emulator, then run: flutter run" -ForegroundColor White
Write-Host "  • iOS:      On a Mac, run: cd ios && pod install && cd .. && flutter run" -ForegroundColor White
Write-Host "  • iOS CI:   Use Codemagic (https://codemagic.io) to build from Windows" -ForegroundColor White
Write-Host ""
Write-Host "Tip: Toggle camera overlay with the eye icon during a session." -ForegroundColor Cyan
