# Refinify

**Refinify** refines your messages with AI before you send them.
It's available for both Windows and macOS platforms.

## Platforms

- **Windows**: Uses AutoHotkey v2 for system-wide keyboard shortcuts
- **macOS**: Uses Hammerspoon for system-wide keyboard shortcuts

Both platforms provide identical functionality with platform-appropriate keyboard shortcuts.

## What does it do?

Refinify takes the text from the currently active edit box in any application—such as `Slack`, `Gmail`, `Notepad`, etc. It sends your text to an AI model, receives a refined version, and appends it to the end of your original text. This way, you can compare both versions and choose which message to use.

## Installation

Download the latest release for your platform from the [GitHub Releases page](https://github.com/moisei-dev/refinify/releases/latest).

### Windows Installation

#### Option 1: Installer (Recommended)
1. **Download** `refinify-windows-X.X.X-installer.msi` from the [latest release](https://github.com/moisei-dev/refinify/releases/latest)
2. **Run the installer**:
   - Double-click the MSI file
   - If AutoHotkey v2 is not installed, the installer will offer to download and install it
   - Choose installation options:
     - ✅ Create desktop shortcut
     - ✅ Run on startup
   - Click "Install"
3. **Configure API Key**:
   - After installation, Refinify will start automatically
   - Press `Ctrl+Alt+K` to open the configuration dialog
   - Enter your OpenAI API key and settings
   - Click "SAVE"

#### Option 2: Portable Archive
1. **Download** `refinify-windows-X.X.X.zip` from the [latest release](https://github.com/moisei-dev/refinify/releases/latest)
2. **Extract** the zip file to your preferred location
3. **Install AutoHotkey v2** from https://www.autohotkey.com/download/ahk-v2.exe
4. **Run Refinify**: Double-click `refinify/refinify-ahk/refinify.ahk`
5. **Configure**: Press `Ctrl+Alt+K` to set up your API key

### macOS Installation

#### Option 1: Installer (Recommended)
1. **Download** `refinify-mac-X.X.X-installer.dmg` from the [latest release](https://github.com/moisei-dev/refinify/releases/latest)
2. **Install the app**:
   - Open the DMG file
   - Drag Refinify.app to Applications folder
   - Launch Refinify from Applications
3. **First run setup**:
   - The app will check for Hammerspoon and offer to install it if needed
   - It will automatically create the necessary symlinks and configuration
   - Grant accessibility permissions when prompted
4. **Configure API Key**:
   - Press `⌘⌥K` to open the configuration dialog
   - Enter your OpenAI API key and settings
   - Click "Save"

#### Option 2: Portable Archive
1. **Download** `refinify-mac-X.X.X.zip` from the [latest release](https://github.com/moisei-dev/refinify/releases/latest)
2. **Extract** to your home directory (`~/`)
3. **Install Hammerspoon**: `brew install --cask hammerspoon`
4. **Set up manually**:
   ```bash
   mkdir -p ~/.hammerspoon
   ln -s ~/refinify/refinify-hammerspoon/refinify.lua ~/.hammerspoon/refinify.lua
   echo 'require("refinify")' >> ~/.hammerspoon/init.lua
   ```
5. **Configure**: Launch Hammerspoon and press `⌘⌥K`

## How to use Refinify
- Place your cursor in the edit box with the text you want to refine. Slack, Gmail, etc.
- Right before sending the message press one of the keystrokes below to refine your text.
  - `Ctrl+Alt+P` (`⌘⌥P` on mac) will replace the original message with the refined message.
  - `Ctrl+Alt+R` (`⌘⌥R` on mac) will append the refined message to the original message.
  - `Ctrl+Alt+K` (`⌘⌥K` on mac) will show the configuration dialog to update API settings.
- Wait for 5 seconds and see the refined text appended to your original message.

**Note**: If your configuration is missing or incomplete (no API key set), the configuration dialog will automatically appear instead of performing the refinement action. Configure your API key and other settings first, then try the refinement again.

**Configuration dialog now allows editing all parameters (API key, endpoint, model, etc.) on both Windows and macOS. The dialog validates numeric fields and creates a backup of your previous configuration.**

## Example
![Before and After](docs/before-after.png)
Suppose you write a message in Slack:
```txt
helo, all, do you aware abiout this isue happend yesterda,?
```

After `Ctrl-Alt-P` your edit box will contain:
```txt
Hello everyone, are you aware of the issue that happened yesterday?
```

After `Ctrl-Alt-R` your edit box will contain:
```txt
helo, all, do you aware abiout this isue happend yesterda,?

Hello everyone, are you aware of the issue that happened yesterday?
```

## Key Features

- ✅ Uses AI to make your messages clearer and more professional
- ✅ Works in any application with an editable text box
- ✅ Keeps your original text—compare with the refined version side-by-side
- ✅ Cross-platform support for Windows and macOS
- ✅ **Single file installation** for macOS (Hammerspoon)
- ✅ Preserves clipboard and restores original content
- ✅ Visual feedback with notifications (macOS)
- ✅ Error handling and user feedback
- ✅ Easy updates via git pull (macOS)

## Configuration

Both platforms require an API key configuration file and provide configuration templates for easy setup.

### API Key Configuration

#### Option 1: Use Configuration Templates

The project includes pre-configured templates for different OpenAI setups. Simply copy the appropriate template to `.env-secrets` and fill in your credentials:

**For Standard OpenAI:**
```bash
# Copy the standard OpenAI template
cp .env-secrets-openai.template .env-secrets
# Edit .env-secrets and add your API key
```

**For Corporate/Enterprise OpenAI:**
```bash
# Copy the corporate OpenAI template (includes preview models)
cp .env-secrets-corporate.template .env-secrets
# Edit .env-secrets and add your corporate OpenAI credentials
```

#### Option 2: Use Configuration Dialog

Both platforms include a comprehensive configuration dialog accessible via **Ctrl+Alt+K** (Windows) or **⌘⌥K** (macOS). This dialog allows you to edit all configuration parameters (API key, endpoint, model, etc.), validates numeric fields, and automatically creates a backup of your previous configuration. This is the recommended method as it ensures your `.env-secrets` file is always properly formatted and up to date.


### Configuration Parameters

| Parameter | Description | Private OpenAI | Corporate/Enterprise OpenAI |
|-----------|-------------|-----------------|------------------|
| `OPENAI_API_KEY` | Your API key | `sk-abc123...` | `corp-abc123...` |
| `OPENAI_ENDPOINT` | API endpoint URL | `https://api.openai.com` | `https://company.openai.azure.com` |
| `OPENAI_API_VERSION` | API version | _(leave empty)_ | `2025-01-01-preview` |
| `OPENAI_MODEL` | Model to use | `gpt-4.1` | `gpt-4.1` |

**Security Note**: Never commit the `.env-secrets` file to version control. It's already included in `.gitignore`.


## Troubleshooting

### Windows
- **Script not running**: Check if green "H" icon is in system tray
- **No response**: Verify API key is correctly set in `.env-secrets` in the project root
- **Permission errors**: Run AutoHotkey as administrator if needed
- **Configuration dialog appears**: If the configuration dialog shows up instead of performing refinement, it means your `.env-secrets` file is missing or the API key is empty. Configure it first, then try again.

### macOS
- **No response**: Check that your API key is correctly set in `~/refinify/.env-secrets`
- **Accessibility errors**: Make sure Hammerspoon has accessibility permissions in System Preferences
- **Module not found**: Ensure `refinify.lua` is linked and your init.lua includes `require("refinify")`
- **API errors**: Check the Hammerspoon console for detailed error messages. If the OpenAI API call fails, a detailed error message will be shown, including your current configuration (API key, endpoint, version, and model) to help with troubleshooting.
- **Configuration dialog appears**: If the configuration dialog shows up instead of performing refinement, it means your `.env-secrets` file is missing or the API key is empty. Configure it first, then try again.

## Project Structure

```
refinify/
├── README.md                          # This file - installation and usage guide
├── .env-secrets-openai.template       # Standard OpenAI configuration template
├── .env-secrets-corporate.template    # Corporate OpenAI configuration template
├── refinify-ahk/                      # Windows implementation
│   ├── _JXON.ahk                      # JSON library for AutoHotkey
│   ├── refinify-generic.ahk           # Core implementation
│   └── refinify.ahk                   # Main entry point
└── refinify-hammerspoon/              # macOS implementation
    └── refinify.lua                   # Complete Hammerspoon implementation
```
