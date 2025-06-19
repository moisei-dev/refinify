#Requires AutoHotkey v2.0
#SingleInstance Force
#Include "_JXON.ahk"

FileEncoding 'UTF-8'

; set default configuration values
global CONFIG_FILE := A_ScriptDir . "/../" . ".env-secrets"
global SYSTEM_PROMPT_FILE := A_ScriptDir . "/../" . "system-prompt-completion.md"
global OPENAI_API_KEY := ""
global OPENAI_ENDPOINT := "https://jfs-ai-use2.openai.azure.com"
global OPENAI_API_VERSION := "2025-01-01-preview"
global OPENAI_MODEL := "gpt-4.1"
global MAX_TOKENS := 800
global TEMPERATURE := 0.7
global TOP_P := 0.95
global FREQUENCY_PENALTY := 0
global PRESENCE_PENALTY := 0
global CUSTOM_COMPLETION_URL := ""

; DEBUG: test message
; MsgBox refineMessage("Note: You'll need your own JFrog OpenAI token, if you don't have one." . FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . "?! ")
; EOF DEBUG

; Ctrl+Alt+P replace refined message over the original message
^!p::
{
    replaceRefinedMessage()
}

; Ctrl+Alt+R append refined message to the original message
^!r::
{
    appendRefinedMessage()
}

; Ctrl+Alt+K show configuration dialog
^!k::
{
    showConfigDialog()
}

; -----------------------------------------------------------------------------
appendRefinedMessage() {
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
; -----------------------------------------------------------------------------

replaceRefinedMessage() {
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

    A_Clipboard := refinedMessage
    WinActivate(originalWin)
    SendInput "^v"
    ; must wait for paste to complete, there is no better way around
    Sleep 100
    A_Clipboard := originalClipboard
}
; -----------------------------------------------------------------------------

refineMessage(userMessage) {
    try {
        openaiResponseText := callOpenAIAPI(userMessage)
        refinedContent := extractMessageContent(openaiResponseText)
        cleanMsg := cleanMessage(refinedContent)
        return cleanMsg
    } catch Error as e {
        return "Request failed: " . e.message . "`n"
        . "Please check your configuration and ensure the OpenAI API is accessible."
        . "`nOPENAI_API_KEY: " . OPENAI_API_KEY
        . "`nOPENAI_ENDPOINT: " . OPENAI_ENDPOINT
        . "`nOPENAI_API_VERSION: " . OPENAI_API_VERSION
        . "`nOPENAI_MODEL: " . OPENAI_MODEL
    }
}

; Build the payload using JXON
constructOpenAIAPIPayload(userMessage) {
    payload := Map()
    payload["model"] := OPENAI_MODEL

    systemMsg := Map()
    systemMsg["role"] := "system"
    systemContent := []
    systemContentObj := Map()
    systemContentObj["type"] := "text"
    systemContentObj["text"] := LoadSystemPrompt()
    systemContent.Push(systemContentObj)
    systemMsg["content"] := systemContent

    messages := []
    messages.Push(systemMsg)

    userMsg := Map()
    userMsg["role"] := "user"
    userMsg["content"] := userMessage
    messages.Push(userMsg)

    payload["messages"] := messages

    ; ensure numeric types for JSON
    payload["max_tokens"] := Integer(MAX_TOKENS)
    payload["temperature"] := Number(TEMPERATURE)
    payload["top_p"] := Number(TOP_P)
    payload["frequency_penalty"] := Number(FREQUENCY_PENALTY)
    payload["presence_penalty"] := Number(PRESENCE_PENALTY)
    ; JXON doesn't support boolean values properly, replacing false and true by 0 or 1. However OpenAI API expects boolean values.
    ; The workaround is to use "false" as a string value. and then StrReplace "false" by false in the String dump
    ; payload["stream"] := "false"

    return JXON_Dump(payload)
}

; Call OpenAI API Completion API to refine the message
callOpenAIAPI(userMessage) {
    LoadConfiguration()
    jsonPayload := constructOpenAIAPIPayload(userMessage)
    ; Send request
    http := ComObject("WinHttp.WinHttpRequest.5.1")
    if CUSTOM_COMPLETION_URL != "" {
        completionUrl := CUSTOM_COMPLETION_URL
    } else if InStr(OPENAI_ENDPOINT, "azure") {
        completionUrl := OPENAI_ENDPOINT . "/openai/deployments/" . OPENAI_MODEL . "/chat/completions?api-version=" . OPENAI_API_VERSION
    } else {
        completionUrl := OPENAI_ENDPOINT . "/v1/chat/completions"
    }
    http.Open("POST", completionUrl, false)
    http.SetRequestHeader("Content-Type", "application/json; charset=utf-8")
    http.SetRequestHeader("api-key", OPENAI_API_KEY)

    http.Send(jsonPayload)
    if (http.Status != 200) {
        throw Error("HTTP Error: " . http.Status . "`nResponse: " . http.ResponseText)
    }

    ; Use BinArr_ToString to properly handle UTF-8 response
    return BinArr_ToString(http.ResponseBody, "UTF-8")
}

; Extract message content from OpenAI API JSON response using JXON library
; expected location: .choices[0].message.content
extractMessageContent(jsonText) {
    jsonObj := JXON_Load(&jsonText)
    if (!jsonObj.Has("choices") || jsonObj["choices"].Length < 1) {
        throw Error("No choices found in response")
    }
    choice := jsonObj["choices"][1]  ; JXON uses 1-based indexing
    if (!choice.Has("message")) {
        throw Error("No message found in first choice")
    }
    message := choice["message"]
    if (!message.Has("content")) {
        throw Error("No content found in message")
    }
    return message["content"]
}

cleanMessage(refinedContent) {
    refinedContent := removeEmptyLines(refinedContent)
    return refinedContent
}

; Remove empty lines from the text
removeEmptyLines(text) {
    result := ""
    for line in StrSplit(text, "`n") {
        if (Trim(line) != "")
            result .= line . "`n"
    }
    return Trim(result)
}

; Convert binary array to string with proper UTF-8 encoding
BinArr_ToString(BinArr, Encoding := "UTF-8") {
    ; https://gist.github.com/tmplinshi/a97d9a99b9aa5a65fd20
    ; https://www.autohotkey.com/boards/viewtopic.php?p=100984#p100984
    oADO := ComObject("ADODB.Stream")
    oADO.Type := 1  ; adTypeBinary
    oADO.Mode := 3  ; adModeReadWrite
    oADO.Open
    oADO.Write(BinArr)
    oADO.Position := 0
    oADO.Type := 2  ; adTypeText
    oADO.Charset := Encoding
    result := oADO.ReadText
    oADO.Close
    return result
}

readProperty(content, keyName, defaultValue := "") {
    if RegExMatch(content, "m)^" . keyName . "=(.*)$", &match) {
        return Trim(match[1], " `t`r`n`"'")
    }
    return defaultValue
}
; -----------------------------------------------------------------------------
LoadConfiguration() {
    global CONFIG_FILE, OPENAI_API_KEY, OPENAI_ENDPOINT, OPENAI_API_VERSION, OPENAI_MODEL, MAX_TOKENS, TEMPERATURE, TOP_P, FREQUENCY_PENALTY, PRESENCE_PENALTY, CUSTOM_COMPLETION_URL
    if !FileExist(CONFIG_FILE) {
        return
    }
    content := FileRead(CONFIG_FILE)
    OPENAI_API_KEY := readProperty(content, "OPENAI_API_KEY", OPENAI_API_KEY)
    OPENAI_ENDPOINT := readProperty(content, "OPENAI_ENDPOINT", OPENAI_ENDPOINT)
    OPENAI_API_VERSION := readProperty(content, "OPENAI_API_VERSION", OPENAI_API_VERSION)
    OPENAI_MODEL := readProperty(content, "OPENAI_MODEL", OPENAI_MODEL)
    MAX_TOKENS := readProperty(content, "MAX_TOKENS", MAX_TOKENS)
    TEMPERATURE := readProperty(content, "TEMPERATURE", TEMPERATURE)
    TOP_P := readProperty(content, "TOP_P", TOP_P)
    FREQUENCY_PENALTY := readProperty(content, "FREQUENCY_PENALTY", FREQUENCY_PENALTY)
    PRESENCE_PENALTY := readProperty(content, "PRESENCE_PENALTY", PRESENCE_PENALTY)
}

; -----------------------------------------------------------------------------
; Save configuration function (moved outside for proper scoping)
ConfigSave(*) {
    global configGui, apiKeyEdit, endpointEdit, apiVersionEdit, openaiModelEdit, completionUrlEdit
    global maxTokensEdit, temperatureEdit, topPEdit, frequencyPenaltyEdit, presencePenaltyEdit
    try {
        FileCopy CONFIG_FILE, CONFIG_FILE . ".bak"
        FileDelete(CONFIG_FILE)
    }
    envContent := "OPENAI_API_KEY=" . apiKeyEdit.Text . "`n"
    envContent .= "OPENAI_ENDPOINT=" . endpointEdit.Text . "`n"
    envContent .= "OPENAI_API_VERSION=" . apiVersionEdit.Text . "`n"
    envContent .= "OPENAI_MODEL=" . openaiModelEdit.Text . "`n"
    envContent .= "CUSTOM_COMPLETION_URL=" . completionUrlEdit.Text . "`n"
    envContent .= "MAX_TOKENS=" . maxTokensEdit.Text . "`n"
    envContent .= "TEMPERATURE=" . temperatureEdit.Text . "`n"
    envContent .= "TOP_P=" . topPEdit.Text . "`n"
    envContent .= "FREQUENCY_PENALTY=" . frequencyPenaltyEdit.Text . "`n"
    envContent .= "PRESENCE_PENALTY=" . presencePenaltyEdit.Text . "`n"
    try {
        FileAppend(envContent, CONFIG_FILE)
    } catch Error as e {
        MsgBox("Error saving configuration: " . e.message)
    }
    configGui.Destroy()
}

; Configuration dialog function
showConfigDialog() {
    global CONFIG_FILE, OPENAI_API_KEY, OPENAI_ENDPOINT, OPENAI_API_VERSION, OPENAI_MODEL, MAX_TOKENS, TEMPERATURE, TOP_P, FREQUENCY_PENALTY, PRESENCE_PENALTY, CUSTOM_COMPLETION_URL
    ; Create GUI
    global configGui := Gui("+Resize", "Refinify Configuration")
    configGui.SetFont("s10")
    ; Add controls with proper label positioning (labels above edit controls)
    configGui.Add("Text", "x20 y20", "[Mandatory] API Key:")
    global apiKeyEdit := configGui.Add("Edit", "x20 y40 w400 h20 Password", OPENAI_API_KEY)

    configGui.Add("Text", "x20 y75", "[Mandatory] Endpoint URL:")
    global endpointEdit := configGui.Add("Edit", "x20 y95 w400 h20", OPENAI_ENDPOINT)

    configGui.Add("Text", "x20 y130", "[Must be empty for OpenAI] API Version:")
    global apiVersionEdit := configGui.Add("Edit", "x20 y150 w400 h20", OPENAI_API_VERSION)

    configGui.Add("Text", "x20 y185", "[Mandatory] OpenAI Model:")
    global openaiModelEdit := configGui.Add("Edit", "x20 y205 w400 h20", OPENAI_MODEL)

    configGui.Add("Text", "x20 y255", " === OPTIONAL PARAMETERS ===")

    configGui.Add("Text", "x20 y300", "Custom Completion URL:")
    global completionUrlEdit := configGui.Add("Edit", "x20 y320 w400 h20", CUSTOM_COMPLETION_URL)

    configGui.Add("Text", "x20 y355", "Max Tokens:")
    global maxTokensEdit := configGui.Add("Edit", "x20 y375 w400 h20", MAX_TOKENS)

    configGui.Add("Text", "x20 y410", "Temperature:")
    global temperatureEdit := configGui.Add("Edit", "x20 y430 w400 h20", Format("{:.2f}", TEMPERATURE))

    configGui.Add("Text", "x20 y465", "Top P:")
    global topPEdit := configGui.Add("Edit", "x20 y485 w400 h20", Format("{:.2f}", TOP_P))

    configGui.Add("Text", "x20 y520", "Frequency Penalty:")
    global frequencyPenaltyEdit := configGui.Add("Edit", "x20 y540 w400 h20", Format("{:.1f}", FREQUENCY_PENALTY))

    configGui.Add("Text", "x20 y575", "Presence Penalty:")
    global presencePenaltyEdit := configGui.Add("Edit", "x20 y595 w400 h20", Format("{:.1f}", PRESENCE_PENALTY))

    ; Add buttons
    saveBtn := configGui.Add("Button", "x20 y630 w80 h30", "SAVE")
    saveBtn.OnEvent("Click", ConfigSave)
    ; Cancel button
    cancelBtn := configGui.Add("Button", "x120 y630 w80 h30", "CANCEL")
    cancelBtn.OnEvent("Click", ConfigCancel)
    ; Show the dialog with proper size
    configGui.Show("w450 h700")
}

; Cancel configuration function (moved outside for proper scoping)
ConfigCancel(*) {
    global configGui
    configGui.Destroy()
}

LoadSystemPrompt() {
    return FileRead(SYSTEM_PROMPT_FILE)
}
