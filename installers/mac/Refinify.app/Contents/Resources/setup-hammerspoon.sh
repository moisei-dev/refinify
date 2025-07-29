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
