Option Explicit

Function CheckAndInstallAutoHotkey()
    Dim objShell, objFSO, objHTTP, objStream
    Dim strAHKUrl, strTempPath, strAHKPath
    Dim intResult
    
    Set objShell = CreateObject("WScript.Shell")
    Set objFSO = CreateObject("Scripting.FileSystemObject")
    
    ' Check if AutoHotkey v2 is already installed
    strAHKPath = ""
    
    ' Check common installation paths
    If objFSO.FileExists("C:\Program Files\AutoHotkey\v2\AutoHotkey.exe") Then
        strAHKPath = "C:\Program Files\AutoHotkey\v2\AutoHotkey.exe"
    ElseIf objFSO.FileExists("C:\Program Files (x86)\AutoHotkey\v2\AutoHotkey.exe") Then
        strAHKPath = "C:\Program Files (x86)\AutoHotkey\v2\AutoHotkey.exe"
    ElseIf objFSO.FileExists(objShell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Programs\AutoHotkey\v2\AutoHotkey.exe") Then
        strAHKPath = objShell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\Programs\AutoHotkey\v2\AutoHotkey.exe"
    End If
    
    ' If AutoHotkey v2 is found, we're done
    If strAHKPath <> "" Then
        Session.Property("AUTOHOTKEYV2FOUND") = "1"
        CheckAndInstallAutoHotkey = 0
        Exit Function
    End If
    
    ' AutoHotkey not found, ask user if they want to install it
    intResult = MsgBox("AutoHotkey v2 is required to run Refinify but was not found on your system." & vbCrLf & vbCrLf & _
                       "Would you like to download and install AutoHotkey v2 now?", _
                       vbYesNo + vbQuestion, "AutoHotkey v2 Required")
    
    If intResult = vbNo Then
        ' User declined, but continue with installation
        CheckAndInstallAutoHotkey = 0
        Exit Function
    End If
    
    ' Download and install AutoHotkey v2
    strAHKUrl = "https://www.autohotkey.com/download/ahk-v2.exe"
    strTempPath = objShell.ExpandEnvironmentStrings("%TEMP%") & "\AutoHotkey_v2_setup.exe"
    
    ' Download the installer
    Set objHTTP = CreateObject("MSXML2.XMLHTTP")
    objHTTP.Open "GET", strAHKUrl, False
    objHTTP.Send
    
    If objHTTP.Status = 200 Then
        Set objStream = CreateObject("ADODB.Stream")
        objStream.Open
        objStream.Type = 1 ' Binary
        objStream.Write objHTTP.ResponseBody
        objStream.SaveToFile strTempPath, 2 ' Overwrite
        objStream.Close
        
        ' Run the installer silently
        objShell.Run """" & strTempPath & """ /S", 1, True
        
        ' Clean up
        objFSO.DeleteFile strTempPath
        
        MsgBox "AutoHotkey v2 has been installed successfully!", vbInformation, "Installation Complete"
    Else
        MsgBox "Failed to download AutoHotkey v2. Please install it manually from:" & vbCrLf & _
               "https://www.autohotkey.com", vbExclamation, "Download Failed"
    End If
    
    CheckAndInstallAutoHotkey = 0
End Function