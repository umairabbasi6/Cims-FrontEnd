# deploy-gh-pages.ps1
# Stop execution on error
$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting Flutter Web Build..." -ForegroundColor Green
flutter build web --release --base-href "/Cims-FrontEnd/" --dart-define=API_BASE_URL="https://cims-backend-gj9r.onrender.com/api"

Write-Host "✅ Build completed successfully." -ForegroundColor Green

# Define paths
$buildWebPath = Join-Path (Get-Location) "build/web"

Write-Host "📦 Initializing temporary git repo in build/web..." -ForegroundColor Blue
Push-Location $buildWebPath

# Cleanup any leftover git state in build/web if it exists
if (Test-Path ".git") {
    Remove-Item -Recurse -Force ".git"
}

# Initialize new repo
git init
git checkout -b gh-pages

# Add files
git add .
git commit -m "Deploy to GitHub Pages"

# Add remote URL from the main repo
$remoteUrl = git -C .. config --get remote.origin.url
if (-not $remoteUrl) {
    # Fallback to hardcoded remote URL if not found
    $remoteUrl = "https://github.com/umairabbasi6/Cims-FrontEnd.git"
}
git remote add origin $remoteUrl

Write-Host "📤 Force pushing build/web to origin/gh-pages..." -ForegroundColor Green
git push --force origin gh-pages

Pop-Location

# Cleanup git directory from build/web so it doesn't interfere
Remove-Item -Recurse -Force (Join-Path $buildWebPath ".git")

Write-Host "🎉 Successfully deployed to GitHub Pages!" -ForegroundColor Green
