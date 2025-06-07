# Refinify for macOS (Hammerspoon) - Simple Installation

This is the macOS version of Refinify using Hammerspoon, equivalent to the Windows AutoHotkey implementation.

## Quick Installation

### 1. Install Hammerspoon
```bash
brew install --cask hammerspoon
```

### 2. Clone and link the single file
```bash
# Clone the repo
git clone https://github.com/your-username/refinify.git ~/refinify

# Create Hammerspoon config directory if needed
mkdir -p ~/.hammerspoon

# Link the refinify file
ln -s ~/refinify/refinify-hammerspoon/refinify.lua ~/.hammerspoon/refinify.lua
```

### 3. Add to your Hammerspoon configuration

Add Refinify to your Hammerspoon configuration (works whether init.lua exists or not):
```bash
# This command works for both new and existing init.lua files
touch ~/.hammerspoon/init.lua && grep -q 'require("refinify")' ~/.hammerspoon/init.lua || echo 'require("refinify")' >> ~/.hammerspoon/init.lua
```

### 4. Configure API Key
```bash
echo 'OPENAI_API_KEY=your_actual_api_key_here' > ~/.hammerspoon/.env-secrets
```

### 5. Start/Reload Hammerspoon
- Launch Hammerspoon from Applications
- Allow accessibility permissions when prompted
- Reload configuration: `Cmd+Shift+R` in Hammerspoon console

## Usage

The keyboard shortcuts are adapted for macOS:

- **Cmd+Alt+R**: Append refined message to original message
- **Cmd+Alt+T**: Replace original message with refined message

Just like the Windows version:
1. Select or place cursor in any text field (Slack, Mail, TextEdit, etc.)
2. Press the keyboard shortcut
3. Wait for the AI to refine your text
4. The refined text will be inserted according to the shortcut used

## Getting Updates

Since the file is linked to the git repository:

```bash
cd ~/refinify
git pull
# Reload Hammerspoon: Cmd+Shift+R
```

## Features

- ✅ **Single file installation** - Just one file to link
- ✅ Works in any macOS application with text input
- ✅ Preserves original text when appending (Cmd+Alt+R)
- ✅ Direct replacement option (Cmd+Alt+T)
- ✅ Same AI refinement logic as Windows version
- ✅ Handles clipboard restoration
- ✅ Visual feedback with notifications
- ✅ Error handling and user feedback
- ✅ Easy updates via git pull

## Troubleshooting

1. **No response**: Check that your API key is correctly set in `~/.hammerspoon/.env-secrets`
2. **Accessibility errors**: Make sure Hammerspoon has accessibility permissions in System Preferences
3. **Module not found**: Ensure `refinify.lua` is linked and your init.lua includes `require("refinify")`
4. **API errors**: Check the Hammerspoon console for detailed error messages

## File Structure

- `refinify.lua` → `~/.hammerspoon/refinify.lua` - Complete Refinify functionality in one file
- `.env-secrets.template` - Template for API key configuration
