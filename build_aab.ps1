# بناء ملف AAB لتطبيق VCenter
# شغّل هذا الملف من PowerShell أو نقراً مزدوجاً

Set-Location $PSScriptRoot

Write-Host "=== تنظيف المشروع ===" -ForegroundColor Cyan
flutter clean

Write-Host "`n=== جلب الحزم ===" -ForegroundColor Cyan
flutter pub get

Write-Host "`n=== بناء AAB (Release) ===" -ForegroundColor Cyan
flutter build appbundle --release

if (Test-Path "build\app\outputs\bundle\release\app-release.aab") {
    Write-Host "`n*** تم إنشاء AAB بنجاح ***" -ForegroundColor Green
    Write-Host "المسار: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green
    explorer "build\app\outputs\bundle\release"
} else {
    Write-Host "`n*** فشل البناء ***" -ForegroundColor Red
    Write-Host "جرّب البناء من Android Studio: Build > Flutter > Build App Bundle" -ForegroundColor Yellow
}

Read-Host "`nاضغط Enter للإغلاق"
