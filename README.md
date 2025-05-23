# Refinify

**Refinify** refines your messages with AI before you send them.
It’s a Windows tool that lets you improve any message directly from any application.

## What does it do?

Refinify takes the text from the currently active edit box in any Windows app—such as Slack, Gmail, Notepad, etc. It sends your text to an AI model, receives a refined version, and appends it to the end of your original text. This way, you can compare both versions and choose which message to use.

## How to use it?

Note: Your `original text remains unchanged`, so you can always go back to it if needed.

- Place your cursor in the edit box with the text you want to refine.
- Activate Refinify. Press `Ctrl-Alt-R`
- Wait for 2-3 seconds and see the refined text appended to your original message.

## Key Features

- Works in any Windows application with an editable text box.
- Uses AI to make your messages clearer and more professional.
- Keeps your original text—compare with the refined version side-by-side.
- Simple and fast workflow.

## Installation
The installation requires two parts: the python handler on WSL and the AHK script on Windows.

### WSL part
Requires Python 3.11 or later and pip.

```bash
git clone ssh://git@git.jfrog.info/xray/refinify.git
cd refinify/refinify-ahk
pip install -r requirements.txt
cat > .env-secrets <<EOF
OPENAI_API_KEY=your_openai_api_key
EOF
```

### Windows part
Requires AutoHotkey v2 installed: https://www.autohotkey.com/download/ahk-v2.exe
Open `refinify/refinify-ahk` WSL directory in Windows Explorer, and double click `refinify.ahk` file.
Notice green `H` icon in the system tray, which means that the script is running.

Run
## Example

Suppose you write a message in Slack:

```
hello, all, are you aware about this issue happend yesterda,?
```

After running Refinify, your edit box will contain:

```
hello, all, are you aware about this issue happend yesterda,?


Hello everyone,
Are you aware of the issue that happened yesterday?
```

## Requirements

* Windows 10 or later. WSL2 with python.
