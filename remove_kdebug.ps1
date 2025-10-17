# Read the file
$content = Get-Content "lib\services\ai_playlist_service.dart" -Raw

# Remove 'if (kDebugMode) {' lines (keeping indentation)
$content = $content -replace '\s*if \(kDebugMode\) \{\r?\n', ''

# Remove standalone closing braces that were part of kDebugMode blocks
# This is tricky, so we'll do it carefully by looking for patterns
$content = $content -replace '(\r?\n\s*)print\([^)]+\);\r?\n\s*\}', '$1print$2'

# Save back
$content | Set-Content "lib\services\ai_playlist_service.dart" -NoNewline

Write-Host "✅ Removed all kDebugMode checks"
