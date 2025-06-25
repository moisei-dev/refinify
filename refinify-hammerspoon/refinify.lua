-- Refinify for Hammerspoon - All-in-one version
-- Equivalent functionality to refinify-generic.ahk
--
-- Installation:
-- 1. Clone repo: git clone https://github.com/your-username/refinify.git ~/refinify
-- 2. Link file: ln -s ~/refinify/refinify-hammerspoon/refinify.lua ~/.hammerspoon/refinify.lua
-- 3. Add to ~/.hammerspoon/init.lua: require("refinify")
-- 4. Create ~/.hammerspoon/.env-secrets with: OPENAI_API_KEY=your_key_here

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local config = {}

-- OpenAI Configuration (equivalent to AutoHotkey constants)
config.OPENAI_ENDPOINT = "https://jfs-ai-use2.openai.azure.com"
config.OPENAI_API_VERSION = "2025-01-01-preview"
config.OPENAI_MODEL = "gpt-4.1"
config.MAX_TOKENS = 800
config.TEMPERATURE = 0.7
config.TOP_P = 0.95
config.FREQUENCY_PENALTY = 0
config.PRESENCE_PENALTY = 0
config.CUSTOM_COMPLETION_URL = ""

-- Load system prompt from file
function config.loadSystemPrompt()
    local scriptDir = debug.getinfo(1, "S").source:match("@?(.*/)")
    local promptFile = scriptDir .. "../system-prompt-completion.md"

    local file = io.open(promptFile, "r")
    local content = file:read("*all")
    file:close()

    return content
end

-- Read configuration from .env-secrets file (equivalent to LoadConfiguration function)
function config.loadConfiguration()
    local scriptDir = debug.getinfo(1, "S").source:match("@?(.*/)")
    local envFile = scriptDir .. "../.env-secrets"
    local file = io.open(envFile, "r")
    if not file then
        return
    end

    local content = file:read("*all")
    file:close()

    -- Helper function equivalent to readProperty
    local function readProperty(content, keyName, defaultValue)
        local pattern = keyName .. "=([^\r\n]*)"
        local match = content:match(pattern)
        if match then
            -- Trim whitespace and quotes
            match = match:gsub("^%s*", ""):gsub("%s*$", "")
            match = match:gsub("^[\"']", ""):gsub("[\"']$", "")
            return match
        end
        return defaultValue or ""
    end

    -- Load all configuration values
    local apiKey = readProperty(content, "OPENAI_API_KEY", "")
    config.OPENAI_ENDPOINT = readProperty(content, "OPENAI_ENDPOINT", config.OPENAI_ENDPOINT)
    config.OPENAI_API_VERSION = readProperty(content, "OPENAI_API_VERSION", config.OPENAI_API_VERSION)
    config.OPENAI_MODEL = readProperty(content, "OPENAI_MODEL", config.OPENAI_MODEL)
    config.CUSTOM_COMPLETION_URL = readProperty(content, "CUSTOM_COMPLETION_URL", config.CUSTOM_COMPLETION_URL)
    config.MAX_TOKENS = tonumber(readProperty(content, "MAX_TOKENS", tostring(config.MAX_TOKENS))) or config.MAX_TOKENS
    config.TEMPERATURE = tonumber(readProperty(content, "TEMPERATURE", tostring(config.TEMPERATURE))) or config.TEMPERATURE
    config.TOP_P = tonumber(readProperty(content, "TOP_P", tostring(config.TOP_P))) or config.TOP_P
    config.FREQUENCY_PENALTY = tonumber(readProperty(content, "FREQUENCY_PENALTY", tostring(config.FREQUENCY_PENALTY))) or config.FREQUENCY_PENALTY
    config.PRESENCE_PENALTY = tonumber(readProperty(content, "PRESENCE_PENALTY", tostring(config.PRESENCE_PENALTY))) or config.PRESENCE_PENALTY

    return apiKey
end

-- Read API key from loaded configuration
function config.readAPIKey()
    return config.loadConfiguration()
end

-- LoadConfiguration function (equivalent to Windows AutoHotkey version)
-- Checks if config file exists and API key is not empty, otherwise shows config dialog
function LoadConfiguration()
    local scriptDir = debug.getinfo(1, "S").source:match("@?(.*/)")
    local envFile = scriptDir .. "../.env-secrets"
    local file = io.open(envFile, "r")
    if file then
        file:close()
        local apiKey = config.readAPIKey()
        if apiKey and apiKey ~= "" then
            -- Configuration is valid, reload it
            config.loadConfiguration()
            return true
        end
    end
    -- Configuration missing or invalid, show dialog
    showConfigDialog()
    return false
end

-- ============================================================================
-- OPENAI API CLIENT
-- ============================================================================

local openai = {}

-- Make HTTP request to OpenAI API (equivalent to callOpenAIAPI function)
function openai.refineMessage(userMessage, callback)
    local apiKey = config.readAPIKey()
    if not apiKey or apiKey == "" then
        callback(nil, "API key not found. Please create ~/.hammerspoon/.env-secrets with OPENAI_API_KEY")
        return
    end

    local payload = openai.constructPayload(userMessage)

    -- Determine completion URL (equivalent to Windows logic)
    local completionUrl
    if config.CUSTOM_COMPLETION_URL ~= "" then
        completionUrl = config.CUSTOM_COMPLETION_URL
    elseif config.OPENAI_ENDPOINT:find("azure") then
        completionUrl = config.OPENAI_ENDPOINT .. "/openai/deployments/" .. config.OPENAI_MODEL .. "/chat/completions?api-version=" .. config.OPENAI_API_VERSION
    else
        completionUrl = config.OPENAI_ENDPOINT .. "/v1/chat/completions"
    end

    -- Make HTTP request
    hs.http.doAsyncRequest(completionUrl, "POST", payload, {
        ["Content-Type"] = "application/json; charset=utf-8",
        ["api-key"] = apiKey
    }, function(status, body, headers)
        if status ~= 200 then
            callback(nil, "HTTP Error: " .. status .. "\nResponse: " .. (body or ""))
            return
        end

        local success, response = pcall(hs.json.decode, body)
        if not success then
            callback(nil, "Failed to parse JSON response")
            return
        end

        local content = openai.extractMessageContent(response)
        if content then
            local cleanContent = openai.cleanMessage(content)
            callback(cleanContent, nil)
        else
            callback(nil, "No content found in response")
        end
    end)
end

-- Construct OpenAI API payload (equivalent to constructOpenAIAPIPayload function)
function openai.constructPayload(userMessage)
    local payload = {
        model = config.OPENAI_MODEL,
        messages = {
            {
                role = "system",
                content = {
                    {
                        type = "text",
                        text = config.loadSystemPrompt()
                    }
                }
            },
            {
                role = "user",
                content = userMessage
            }
        },
        max_tokens = config.MAX_TOKENS,
        temperature = config.TEMPERATURE,
        top_p = config.TOP_P,
        frequency_penalty = config.FREQUENCY_PENALTY,
        presence_penalty = config.PRESENCE_PENALTY
    }

    return hs.json.encode(payload)
end

-- Extract message content from OpenAI response (equivalent to extractMessageContent function)
function openai.extractMessageContent(response)
    if not response.choices or #response.choices < 1 then
        return nil
    end

    local choice = response.choices[1]
    if not choice.message or not choice.message.content then
        return nil
    end

    return choice.message.content
end

-- Clean message by removing empty lines (equivalent to cleanMessage function)
function openai.cleanMessage(content)
    if not content then return "" end

    local lines = {}
    for line in content:gmatch("[^\r\n]+") do
        if line:match("%S") then -- If line contains non-whitespace characters
            table.insert(lines, line)
        end
    end

    return table.concat(lines, "\n")
end

-- ============================================================================
-- CORE REFINIFY FUNCTIONALITY
-- ============================================================================

local refinify = {}

-- Helper function to get and set clipboard content
local function getClipboard()
    return hs.pasteboard.getContents()
end

local function setClipboard(content)
    hs.pasteboard.setContents(content)
end

-- Helper function to simulate keyboard shortcuts
local function sendKeys(modifiers, key)
    hs.eventtap.keyStroke(modifiers, key)
end

-- Main refinement function - equivalent to replaceRefinedMessage
local function replaceRefinedMessage()
    -- Check configuration first
    if not LoadConfiguration() then
        return
    end

    -- Save original clipboard
    local originalClipboard = getClipboard()

    -- Clear clipboard and copy current text
    setClipboard("")
    sendKeys({"cmd"}, "a")  -- Select all (Cmd+A on macOS)
    sendKeys({"cmd"}, "c")  -- Copy (Cmd+C on macOS)

    -- Wait for clipboard to be populated
    hs.timer.doAfter(0.1, function()
        local originalMessage = getClipboard()

        if not originalMessage or originalMessage == "" then
            hs.alert.show("The attempt to copy text onto the clipboard failed.")
            setClipboard(originalClipboard)
            return
        end

        -- Show processing notification
        hs.alert.show("Refining message...")

        -- Call OpenAI API
        openai.refineMessage(originalMessage, function(refinedMessage, error)
            if error then
                local errorMsg = "Request failed: " .. error .. "\n" ..
                    "Please check your configuration and ensure the OpenAI API is accessible."
                hs.alert.show("Error: " .. error)
                setClipboard(originalClipboard)
                return
            end

            -- Replace with refined message
            setClipboard(refinedMessage)
            sendKeys({"cmd"}, "v")  -- Paste (Cmd+V on macOS)

            -- Wait for paste to complete, then restore original clipboard
            hs.timer.doAfter(0.1, function()
                setClipboard(originalClipboard)
            end)

            hs.alert.show("Message refined!")
        end)
    end)
end

-- Main refinement function - equivalent to appendRefinedMessage
local function appendRefinedMessage()
    -- Check configuration first
    if not LoadConfiguration() then
        return
    end

    -- Save original clipboard
    local originalClipboard = getClipboard()

    -- Clear clipboard and copy current text
    setClipboard("")
    sendKeys({"cmd"}, "a")  -- Select all (Cmd+A on macOS)
    sendKeys({"cmd"}, "c")  -- Copy (Cmd+C on macOS)

    -- Wait for clipboard to be populated
    hs.timer.doAfter(0.1, function()
        local originalMessage = getClipboard()

        if not originalMessage or originalMessage == "" then
            hs.alert.show("The attempt to copy text onto the clipboard failed.")
            setClipboard(originalClipboard)
            return
        end

        -- Show processing notification
        hs.alert.show("Refining message...")

        -- Call OpenAI API
        openai.refineMessage(originalMessage, function(refinedMessage, error)
            if error then
                local errorMsg = "Request failed: " .. error .. "\n" ..
                    "Please check your configuration and ensure the OpenAI API is accessible."
                hs.alert.show("Error: " .. error)
                setClipboard(originalClipboard)
                return
            end

            -- Append refined message to original
            local clipboardContent = originalMessage .. "\n\n" .. refinedMessage .. "\n"
            setClipboard(clipboardContent)
            sendKeys({"cmd"}, "v")  -- Paste (Cmd+V on macOS)

            -- Wait for paste to complete, then restore original clipboard
            hs.timer.doAfter(0.1, function()
                setClipboard(originalClipboard)
            end)

            hs.alert.show("Message refined!")
        end)
    end)
end

-- Configuration dialog function (equivalent to showConfigDialog in AutoHotkey)
function showConfigDialog()
    -- Load current configuration
    local currentApiKey = config.readAPIKey() or ""

    -- Create a simple text input dialog
    local button, result = hs.dialog.textPrompt("Refinify Configuration",
        "Enter your OpenAI API Key:", currentApiKey, "OK", "Cancel")

    if button == "OK" and result and result ~= "" then
        -- Save configuration to .env-secrets file (equivalent to ConfigSave)
        local scriptDir = debug.getinfo(1, "S").source:match("@?(.*/)")
        local envFile = scriptDir .. "../.env-secrets"
        local file = io.open(envFile, "w")
        if file then
            local envContent = "OPENAI_API_KEY=" .. result .. "\n" ..
                "OPENAI_ENDPOINT=" .. config.OPENAI_ENDPOINT .. "\n" ..
                "OPENAI_API_VERSION=" .. config.OPENAI_API_VERSION .. "\n" ..
                "OPENAI_MODEL=" .. config.OPENAI_MODEL .. "\n" ..
                "CUSTOM_COMPLETION_URL=" .. config.CUSTOM_COMPLETION_URL .. "\n" ..
                "MAX_TOKENS=" .. config.MAX_TOKENS .. "\n" ..
                "TEMPERATURE=" .. config.TEMPERATURE .. "\n" ..
                "TOP_P=" .. config.TOP_P .. "\n" ..
                "FREQUENCY_PENALTY=" .. config.FREQUENCY_PENALTY .. "\n" ..
                "PRESENCE_PENALTY=" .. config.PRESENCE_PENALTY .. "\n"

            file:write(envContent)
            file:close()

            -- Reload configuration
            config.readAPIKey()

            hs.alert.show("Configuration saved successfully!")
            return true
        else
            hs.alert.show("Error: Could not save configuration file")
            return false
        end
    end
    return false
end

-- Initialize keyboard shortcuts and setup (equivalent to AutoHotkey hotkey definitions)
function refinify.init()
    -- Load configuration on startup
    config.readAPIKey()

    -- Cmd+Alt+P: Replace refined message over original message (equivalent to ^!p::)
    hs.hotkey.bind({"cmd", "alt"}, "P", function()
        replaceRefinedMessage()
    end)

    -- Cmd+Alt+R: Append refined message to original message (equivalent to ^!r::)
    hs.hotkey.bind({"cmd", "alt"}, "R", function()
        appendRefinedMessage()
    end)

    -- Cmd+Alt+K: Show configuration dialog (equivalent to ^!k::)
    hs.hotkey.bind({"cmd", "alt"}, "K", function()
        showConfigDialog()
    end)

    hs.alert.show("Refinify loaded! Use Cmd+Alt+P (replace) or Cmd+Alt+R (append)")
end

-- Auto-initialize when module is loaded
refinify.init()

-- Return the module for manual initialization if needed
return refinify
