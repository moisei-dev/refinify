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
cp ../../system-prompt-completion.md "$RESOURCES_DIR/"
# Copy .env-secrets files if they exist
find ../.. -maxdepth 1 -name ".env-secrets*" -exec cp {} "$RESOURCES_DIR/" \; 2>/dev/null || true

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

# Start Hammerspoon
open -a Hammerspoon

osascript -e 'display dialog "Setup complete!\n\nHammerspoon has been configured with Refinify.\n\nPress ⌘⌥K to configure your API key." buttons {"OK"} default button "OK"'
EOF

chmod +x "$RESOURCES_DIR/setup-hammerspoon.sh"

echo "Refinify.app created successfully"