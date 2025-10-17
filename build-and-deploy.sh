#!/bin/bash
# build-and-deploy.sh - Automated web build and GitHub Pages deployment

set -e

echo "🏗️  Starting Flutter web build and deployment..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Clean previous build
echo -e "${BLUE}1️⃣  Cleaning previous build...${NC}"
flutter clean

# 2. Get dependencies
echo -e "${BLUE}2️⃣  Getting dependencies...${NC}"
flutter pub get

# 3. Build web release
echo -e "${BLUE}3️⃣  Building web release...${NC}"
flutter build web --release --base-href="/spotify-ai-music-app/"

# 4. Copy to docs folder
echo -e "${BLUE}4️⃣  Copying to docs folder for GitHub Pages...${NC}"
rm -rf docs/*
cp -r build/web/* docs/

# 5. Git operations
echo -e "${BLUE}5️⃣  Committing to git...${NC}"
git add -A
git commit -m "build: automated web release deployment to GitHub Pages"

echo -e "${BLUE}6️⃣  Pushing to GitHub...${NC}"
git push

echo -e "${GREEN}✅ Deployment complete!${NC}"
echo -e "${YELLOW}Your app is live at: https://byflowt.github.io/spotify-ai-music-app/${NC}"
