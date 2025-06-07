# Refinify for macOS (Hammerspoon)

This is the macOS version of Refinify using Hammerspoon, equivalent to the Windows AutoHotkey implementation.

## Installation

### 1. Install Hammerspoon
```bash
brew install --cask hammerspoon
```

### 2. Set up the Refinify module
Copy the files from this directory to your Hammerspoon configuration:

```bash
# Create Hammerspoon config directory if it doesn't exist
mkdir -p ~/.hammerspoon

# Copy all .lua files to Hammerspoon directory
cp refinify-hammerspoon/*.lua ~/.hammerspoon/

# Copy the init.lua as your main Hammerspoon config (or merge with existing)
cp refinify-hammerspoon/init.lua ~/.hammerspoon/
```

### 3. Configure API Key
Create a `.env-secrets` file in your home directory:

```bash
# Copy the template
cp refinify-hammerspoon/.env-secrets.template ~/.env-secrets

# Edit with your actual API key
nano ~/.env-secrets
```

Add your OpenAI API key:
```ini
OPENAI_API_KEY=your_actual_api_key_here
```

### 4. Start Hammerspoon
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

## Features

- ✅ Works in any macOS application with text input
- ✅ Preserves original text when appending (Cmd+Alt+R)
- ✅ Direct replacement option (Cmd+Alt+T)
- ✅ Same AI refinement logic as Windows version
- ✅ Handles clipboard restoration
- ✅ Visual feedback with notifications
- ✅ Error handling and user feedback

## Troubleshooting

1. **No response**: Check that your API key is correctly set in `~/.env-secrets`
2. **Accessibility errors**: Make sure Hammerspoon has accessibility permissions in System Preferences
3. **Module not found**: Ensure all `.lua` files are in `~/.hammerspoon/`
4. **API errors**: Check the Hammerspoon console for detailed error messages

## File Structure

- `init.lua` - Main entry point, loads Refinify module
- `refinify.lua` - Core functionality and keyboard shortcuts
- `config.lua` - Configuration constants and API key management
- `openai.lua` - OpenAI API client and response handling
- `.env-secrets.template` - Template for API key configuration
