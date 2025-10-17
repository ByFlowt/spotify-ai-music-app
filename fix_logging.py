import re

# Read the file
with open('lib/services/ai_playlist_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern to match: if (kDebugMode) { print(...); }
# Replace with: _log(...);
pattern = r'if \(kDebugMode\) \{\s*print\((.*?)\);\s*\}'
replacement = r'_log(\1);'
content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Write back
with open('lib/services/ai_playlist_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Replaced all kDebugMode blocks with _log calls")
