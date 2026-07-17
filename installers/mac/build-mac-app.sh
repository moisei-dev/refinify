#!/bin/bash
set -e

VERSION=$1
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

echo "Building Refinify.app for macOS..."

# Create app structure
APP_DIR="Refinify.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>refinify-launcher</string>
    <key>CFBundleIdentifier</key>
    <string>com.moiseidev.refinify</string>
    <key>CFBundleName</key>
    <string>Refinify</string>
    <key>CFBundleDisplayName</key>
    <string>Refinify</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.12</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Create launcher script
cat > "$MACOS_DIR/refinify-launcher" << 'EOF'
#!/bin/bash

# Get the directory where the app is installed
APP_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
RESOURCES_DIR="$APP_DIR/Contents/Resources"

# Check if this is first run
if [ ! -f "$HOME/.refinify-installed" ]; then
    # Run setup script
    osascript -e 'display dialog "Refinify will now set up Hammerspoon integration.\n\nThis will:\n1. Check if Hammerspoon is installed\n2. Create necessary symlinks\n3. Configure Hammerspoon to load Refinify\n\nClick OK to continue." buttons {"OK", "Cancel"} default button "OK"'
    
    if [ $? -eq 0 ]; then
        "$RESOURCES_DIR/setup-hammerspoon.sh"
        touch "$HOME/.refinify-installed"
    fi
fi

# Open configuration dialog
osascript -e 'display dialog "Refinify is installed!\n\nPress ⌘⌥K in any text field to configure your API key.\nPress ⌘⌥P to replace text with refined version.\nPress ⌘⌥R to append refined text.\n\nRefer to the README for more information." buttons {"OK"} default button "OK"'
EOF

chmod +x "$MACOS_DIR/refinify-launcher"

# Copy resources
cp -r ../../refinify-hammerspoon "$RESOURCES_DIR/"
cp ../../README.md "$RESOURCES_DIR/"
cp ../../system-prompt-completion.md "$RESOURCES_DIR/refinify-system-prompt-default.md"
# Copy config templates so first-run setup can seed a real default
cp ../../refinify-secrets-openai.template "$RESOURCES_DIR/"
cp ../../refinify-secrets-corporate.template "$RESOURCES_DIR/"

# Create setup script
cat > "$RESOURCES_DIR/setup-hammerspoon.sh" << 'EOF'
#!/bin/bash

RESOURCES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Check if Hammerspoon is installed
if ! [ -d "/Applications/Hammerspoon.app" ]; then
    osascript -e 'display dialog "Hammerspoon is not installed.\n\nWould you like to install it now using Homebrew?" buttons {"Install", "Cancel"} default button "Install"'

    if [ $? -eq 0 ]; then
        # Check if Homebrew is installed
        if ! command -v brew &> /dev/null; then
            osascript -e 'display dialog "Homebrew is not installed. Please install Homebrew first:\n\n/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"\n\nThen run Refinify again." buttons {"OK"} default button "OK"'
            exit 1
        fi

        # Install Hammerspoon
        brew install --cask hammerspoon

        # Cask installs can lag - wait for the app bundle to actually appear
        for i in $(seq 1 30); do
            [ -d "/Applications/Hammerspoon.app" ] && break
            sleep 1
        done
        if ! [ -d "/Applications/Hammerspoon.app" ]; then
            osascript -e 'display dialog "Hammerspoon installation did not complete.\n\nPlease install Hammerspoon manually from https://www.hammerspoon.org and run Refinify again." buttons {"OK"} default button "OK"'
            exit 1
        fi
    else
        exit 1
    fi
fi

# Create Hammerspoon config directory
mkdir -p "$HOME/.hammerspoon"

# Create symlink
ln -sf "$RESOURCES_DIR/refinify-hammerspoon/refinify.lua" "$HOME/.hammerspoon/refinify.lua"

# Add to init.lua if not already present
if ! grep -q 'require("refinify")' "$HOME/.hammerspoon/init.lua" 2>/dev/null; then
    echo 'require("refinify")' >> "$HOME/.hammerspoon/init.lua"
fi

# Set up the config directory Refinify reads secrets/prompt from
CONFIG_DIR="$HOME/.config/refinify"
mkdir -p "$CONFIG_DIR"

# Migrate legacy manual/portable install layout (~/refinify/) — checked first
if [ -d "$HOME/refinify" ]; then
    [ -f "$HOME/refinify/.env-secrets" ] && [ ! -f "$CONFIG_DIR/refinify-secrets" ] && \
        cp "$HOME/refinify/.env-secrets" "$CONFIG_DIR/refinify-secrets"
    [ -f "$HOME/refinify/system-prompt-completion.md" ] && [ ! -f "$CONFIG_DIR/refinify-system-prompt.md" ] && \
        cp "$HOME/refinify/system-prompt-completion.md" "$CONFIG_DIR/refinify-system-prompt.md"
    rm -rf "$HOME/refinify"
fi

# Migrate legacy files from ~/.hammerspoon (existing users of the old scheme)
[ -f "$HOME/.hammerspoon/.env-secrets" ] && [ ! -f "$CONFIG_DIR/refinify-secrets" ] && \
    cp "$HOME/.hammerspoon/.env-secrets" "$CONFIG_DIR/refinify-secrets"
[ -f "$HOME/.hammerspoon/system-prompt-completion.md" ] && [ ! -f "$CONFIG_DIR/refinify-system-prompt.md" ] && \
    cp "$HOME/.hammerspoon/system-prompt-completion.md" "$CONFIG_DIR/refinify-system-prompt.md"

# Seed defaults for genuinely new installs
[ ! -f "$CONFIG_DIR/refinify-secrets" ] && cp "$RESOURCES_DIR/refinify-secrets-openai.template" "$CONFIG_DIR/refinify-secrets"
[ ! -f "$CONFIG_DIR/refinify-system-prompt.md" ] && cp "$RESOURCES_DIR/refinify-system-prompt-default.md" "$CONFIG_DIR/refinify-system-prompt.md"

# Start Hammerspoon and wait for it to actually be running (don't assume open succeeded)
open -a Hammerspoon
HS_RUNNING=false
for i in $(seq 1 15); do
    if pgrep -x Hammerspoon > /dev/null; then
        HS_RUNNING=true
        break
    fi
    sleep 1
done
if [ "$HS_RUNNING" = false ]; then
    open -a Hammerspoon
    for i in $(seq 1 15); do
        if pgrep -x Hammerspoon > /dev/null; then
            HS_RUNNING=true
            break
        fi
        sleep 1
    done
fi
if [ "$HS_RUNNING" = false ]; then
    osascript -e 'display dialog "Hammerspoon did not start.\n\nPlease launch Hammerspoon manually from Applications, then re-open Refinify." buttons {"OK"} default button "OK"'
    exit 1
fi

# Hammerspoon needs Accessibility access to simulate keystrokes/paste - a
# fresh install almost never has this granted yet. Loop until the user
# confirms it (TCC.db is usually unreadable without Full Disk Access, so we
# can't verify this programmatically - trust the explicit confirmation).
ACCESSIBILITY_GRANTED=false
while [ "$ACCESSIBILITY_GRANTED" = false ]; do
    RESPONSE=$(osascript -e 'display dialog "Refinify needs Accessibility access (via Hammerspoon) to work.\n\n1. Click \"Open Settings\" below\n2. Enable Hammerspoon under Privacy & Security > Accessibility\n3. Come back and click \"Done\"" buttons {"Open Settings", "Done"} default button "Open Settings"')
    if [[ "$RESPONSE" == *"Open Settings"* ]]; then
        open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        osascript -e 'display dialog "Enable Hammerspoon in the Accessibility list, then click Done." buttons {"Done"} default button "Done"'
        ACCESSIBILITY_GRANTED=true
    else
        ACCESSIBILITY_GRANTED=true
    fi
done

# Force Hammerspoon to reload so the newly-symlinked refinify.lua takes
# effect immediately, without requiring a manual quit/reopen.
osascript -e 'tell application "Hammerspoon" to execute lua code "hs.reload()"' > /dev/null 2>&1

osascript -e 'display dialog "Setup complete!\n\nHammerspoon has been configured with Refinify.\n\nPress ⌘⌥K to configure your API key." buttons {"OK"} default button "OK"'
EOF

chmod +x "$RESOURCES_DIR/setup-hammerspoon.sh"

echo "Refinify.app created successfully"