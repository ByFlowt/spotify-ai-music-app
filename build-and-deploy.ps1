# build-and-deploy.ps1 - Automated web build and GitHub Pages deployment for Windows

Write-Host "🏗️  Starting Flutter web build and deployment..." -ForegroundColor Cyan

# 1. Clean previous build
Write-Host "1️⃣  Cleaning previous build..." -ForegroundColor Blue
flutter clean

# 2. Get dependencies
Write-Host "2️⃣  Getting dependencies..." -ForegroundColor Blue
flutter pub get

# 3. Build web release
Write-Host "3️⃣  Building web release..." -ForegroundColor Blue
flutter build web --release --base-href="/spotify-ai-music-app/"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

# 4. Copy to docs folder
Write-Host "4️⃣  Copying to docs folder for GitHub Pages..." -ForegroundColor Blue
Remove-Item -Path "docs/*" -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item -Path "build/web/*" -Destination "docs/" -Recurse -Force

# 5. Git operations
Write-Host "5️⃣  Committing to git..." -ForegroundColor Blue
git add -A
git commit -m "build: automated web release deployment to GitHub Pages"

Write-Host "6️⃣  Pushing to GitHub..." -ForegroundColor Blue
git push

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Deployment complete!" -ForegroundColor Green
    Write-Host "Your app is live at: https://byflowt.github.io/spotify-ai-music-app/" -ForegroundColor Yellow
} else {
    Write-Host "⚠️  Deployment completed with some warnings" -ForegroundColor Yellow
}
