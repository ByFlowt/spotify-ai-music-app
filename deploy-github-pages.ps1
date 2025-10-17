# GitHub Pages Deployment Script for Flutter Web
# This script builds and deploys the app to GitHub Pages

Write-Host "🚀 Starting GitHub Pages deployment..." -ForegroundColor Cyan

# Step 1: Build Flutter web app with correct base-href
Write-Host "`n📦 Building Flutter web app..." -ForegroundColor Yellow
flutter build web --release --base-href /spotify-ai-music-app/

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build completed successfully!" -ForegroundColor Green

# Step 2: Copy to docs folder for GitHub Pages
Write-Host "`n📂 Copying build to docs folder..." -ForegroundColor Yellow
Remove-Item -Recurse -Force docs -ErrorAction SilentlyContinue
Copy-Item -Recurse build\web docs

Write-Host "✅ Files copied to docs folder!" -ForegroundColor Green

# Step 3: Git add, commit, and push
Write-Host "`n📤 Deploying to GitHub Pages..." -ForegroundColor Yellow
git add .
git commit -m "Deploy: Update GitHub Pages deployment ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
git push

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Git push failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n✅ Deployment complete!" -ForegroundColor Green
Write-Host "🌐 Your app will be available at: https://byflowt.github.io/spotify-ai-music-app/" -ForegroundColor Cyan
Write-Host "⏱️  GitHub Pages may take 1-2 minutes to update." -ForegroundColor Yellow
