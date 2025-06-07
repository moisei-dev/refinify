# Refinify

**Refinify** refines your messages with AI before you send them.
It's available for both Windows and macOS platforms.

## Platforms

- **Windows**: Uses AutoHotkey v2 (see `refinify-ahk/` directory)
- **macOS**: Uses Hammerspoon (see `refinify-hammerspoon/` directory)

## What does it do?

Refinify takes the text from the currently active edit box in any application—such as `Slack`, `Gmail`, `Notepad`, etc. It sends your text to an AI model, receives a refined version, and appends it to the end of your original text. This way, you can compare both versions and choose which message to use.

## How to use it?

Note: Your `original text remains unchanged`, so you can always go back to it if needed.

### Windows (AutoHotkey)
- Place your cursor in the edit box with the text you want to refine. Slack, Gmail, etc.
- Right before sending the message press `Ctrl-Alt-T` or `Ctrl-Alt-R` to refine your text.
  - `Ctrl-Alt-T` will replace the original message with the refined message.
  - `Ctrl-Alt-R` will append the refined message to the original message.

### macOS (Hammerspoon)
- Place your cursor in the edit box with the text you want to refine. Slack, Mail, etc.
- Right before sending the message press `Cmd-Alt-T` or `Cmd-Alt-R` to refine your text.
  - `Cmd-Alt-T` will replace the original message with the refined message.
  - `Cmd-Alt-R` will append the refined message to the original message.

Wait for 5 seconds and see the refined text appended to your original message.

## Key Features

- Uses AI to make your messages clearer and more professional.
- Works in any application with an editable text box.
- Keeps your original text—compare with the refined version side-by-side.
- Cross-platform support for Windows and macOS.

## Installation

### Windows (AutoHotkey)
- Install `AutoHotkey v2` from https://www.autohotkey.com/download/ahk-v2.exe
- Clone `Refinify` git repo: `ssh://git@git.jfrog.info/xray/refinify.git`. `C:\Users\your_username\refinify` is a good place.
- Create `.env-secrets` file in `refinify/refinify-ahk` directory with your OpenAI API key.
    ```ini
    OPENAI_API_KEY=your_openai_api_key_here_without_quotes
    ```
- Browse to `refinify/refinify-ahk` directory in the Windows Explorer, and double click `refinify.ahk` file.
- Notice green `H` icon in the system tray, which means that the script is running.
- Now you can use Refinify in any application with an editable text box. Press `Ctrl-Alt-R` to refine your text and Enjoy!

### macOS (Hammerspoon)
- Install Hammerspoon: `brew install --cask hammerspoon`
- Copy the Lua files from `refinify-hammerspoon/` to `~/.hammerspoon/`
- Create `~/.env-secrets` file with your OpenAI API key
- Launch Hammerspoon and allow accessibility permissions
- See detailed instructions in `refinify-hammerspoon/README.md`

## Example
