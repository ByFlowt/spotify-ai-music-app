#!/usr/bin/env pwsh
# Quick setup script to add Vercel environment variables

Write-Host "🔧 Vercel Environment Variables Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "⚠️  You need to add these environment variables to Vercel Dashboard:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Go to: https://vercel.com/byflowt-prod-tests-projects/backend_proxy/settings/environment-variables" -ForegroundColor Green
Write-Host ""

$envVars = @(
    @{Name="SPOTIFY_CLIENT_ID"; Value="ce1797970d2d4ec8852fa68a54fe8a8f"; Required=$true},
    @{Name="SPOTIFY_CLIENT_SECRET"; Value="2eb0d963befb41f0998ddd703c8a8b7a"; Required=$true},
    @{Name="GEMINI_API_KEY"; Value="AIzaSyDaKqVBlnGR6UXq5XQjxo7mJDfgVZ9t0NU"; Required=$false},
    @{Name="AUDD_API_KEY"; Value="3cb567377b824e96657c208fcf07d2bf"; Required=$false}
)

Write-Host "Environment Variables to Add:" -ForegroundColor Cyan
Write-Host "-----------------------------" -ForegroundColor Cyan
foreach ($var in $envVars) {
    $status = if ($var.Required) { "✅ REQUIRED" } else { "⚪ Optional" }
    Write-Host "$($var.Name) = $($var.Value)" -ForegroundColor White
    Write-Host "  Status: $status" -ForegroundColor $(if ($var.Required) { "Red" } else { "Gray" })
    Write-Host ""
}

Write-Host "`n📋 Steps:" -ForegroundColor Cyan
Write-Host "1. Click the link above to open Vercel dashboard" -ForegroundColor White
Write-Host "2. Click 'Add Variable' button" -ForegroundColor White
Write-Host "3. Copy-paste each variable name and value" -ForegroundColor White
Write-Host "4. Select: Production, Preview, and Development" -ForegroundColor White
Write-Host "5. Click 'Save'" -ForegroundColor White
Write-Host "6. Repeat for all variables" -ForegroundColor White
Write-Host ""

Write-Host "After adding all variables, run:" -ForegroundColor Cyan
Write-Host "  cd backend-proxy-example" -ForegroundColor Yellow
Write-Host "  vercel --prod" -ForegroundColor Yellow
Write-Host ""

$response = Read-Host "Have you added all the environment variables? (y/n)"
if ($response -eq "y" -or $response -eq "Y") {
    Write-Host "`n🚀 Deploying to Vercel..." -ForegroundColor Green
    Set-Location backend-proxy-example
    vercel --prod
    Set-Location ..
    Write-Host "`n✅ Deployment complete!" -ForegroundColor Green
    Write-Host "Your Spotify authentication should now work!" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  Please add the environment variables first, then run this script again." -ForegroundColor Yellow
    Write-Host "Or manually deploy with: cd backend-proxy-example && vercel --prod" -ForegroundColor Yellow
}
