# Configuration Setup

This directory contains configuration files for the BibleStudy app.

## Quick Start

1. Copy the template file to create your secrets file:
   ```bash
   cp Config/Secrets.xcconfig.template Config/Secrets.xcconfig
   ```

2. Edit `Config/Secrets.xcconfig` and add your API keys:
   ```
   SUPABASE_URL = https://your-project.supabase.co
   SUPABASE_ANON_KEY = your-supabase-anon-key
   OPENAI_API_KEY = sk-your-openai-api-key
   ```

3. Configure Xcode to use the xcconfig files (one-time setup):
   - Open the project in Xcode
   - Select the project in the navigator
   - Select the project (not target) in the editor
   - Go to the "Info" tab
   - Under "Configurations", set:
     - Debug → `Config/Debug.xcconfig`
     - Release → `Config/Release.xcconfig`

4. Add Info.plist entries for the keys:
   - Select your target → "Info" tab
   - Add these custom iOS Target Properties:
     - `SUPABASE_URL` = `$(SUPABASE_URL)`
     - `SUPABASE_ANON_KEY` = `$(SUPABASE_ANON_KEY)`
     - `OPENAI_API_KEY` = `$(OPENAI_API_KEY)`

## File Structure

```
Config/
├── README.md                    # This file
├── Secrets.xcconfig.template    # Template (committed to git)
├── Secrets.xcconfig             # Your actual secrets (gitignored)
├── Debug.xcconfig               # Debug build settings
└── Release.xcconfig             # Release build settings
```

## Security Notes

- `Secrets.xcconfig` is listed in `.gitignore` and should NEVER be committed
- The template file shows the required format but contains no real credentials
- In CI/CD, use environment variables or secure secret management

## Troubleshooting

If the app crashes on launch with "Missing SUPABASE_URL" or similar:

1. Verify `Config/Secrets.xcconfig` exists and has valid values
2. Verify Xcode is configured to use the xcconfig files
3. Verify Info.plist entries are correctly referencing `$(VARIABLE_NAME)`
4. Clean build folder (Cmd+Shift+K) and rebuild

## Getting API Keys

### Supabase
1. Go to [supabase.com](https://supabase.com)
2. Create a project or use existing one
3. Go to Project Settings → API
4. Copy the URL and anon/public key

### OpenAI
1. Go to [platform.openai.com](https://platform.openai.com)
2. Navigate to API Keys
3. Create a new API key
4. Copy the key (it's only shown once)
