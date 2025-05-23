#Requires AutoHotkey v2.0
#SingleInstance Force

; FIX THE PATH BELOW ACCORDING TO YOUR SYSTEM
WSL_SCRIPT_DIR := '/home/moiseir/jfrog/mcp/refinify/refinify-ahk'

; DON'T CHANGE ANYTHING BELOW THIS LINE
USERNAME := EnvGet("USERNAME")
WSL_TEMP_DIR := "/mnt/c/Users/" . USERNAME . "/AppData/Local/Temp/refinify"
WSL_SCRIPT_FILE := WSL_SCRIPT_DIR . "/refinify-handler.py"
WSL_INPUT_FILE := WSL_TEMP_DIR . "/in.txt"
WSL_OUTPUT_FILE := WSL_TEMP_DIR . "/out.txt"

; DEBUG: test message
; MsgBox refineMessage("hello, all, are you aware about this issue happend yesterda,? " . FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . "?! ")
; EOF DEBUG

; Hotkey to refine the message in the clipboard Ctrl+Alt+R
^!r::
{
    originalWin := WinGetID("A")
    originalClipboard := A_Clipboard
    A_Clipboard := ""
    SendInput "^a"
    SendInput "^c"
    if !ClipWait(2) {
        MsgBox "The attempt to copy text onto the clipboard failed."
        return
    }
    originalMessage := A_Clipboard
    refinedMessage := refineMessage(originalMessage)

    A_Clipboard := originalMessage "`n" "`n" refinedMessage "`n"
    WinActivate(originalWin)
    SendInput "^v"
    ; must wait for paste to complete, there is no better way around
    Sleep 100
    A_Clipboard := originalClipboard
}

refineMessage(userMessage) {
    tempDir := EnvGet("TEMP") . "\refinify"
    DirCreate tempDir
    inFile := tempDir . "\in.txt"
    outFile := tempDir . "\out.txt"
    if FileExist(inFile)
        FileDelete(inFile)
    if FileExist(outFile)
        FileDelete(outFile)
    FileAppend userMessage, inFile, "UTF-8"
    cmd := "wsl python3.11 " . WSL_SCRIPT_FILE . " --input-file " . WSL_INPUT_FILE . " --output-file " . WSL_OUTPUT_FILE
    shell := ComObject('WScript.Shell')
    exec := shell.Run(cmd, 0, true)
    return FileRead(outFile, "UTF-8")
}
