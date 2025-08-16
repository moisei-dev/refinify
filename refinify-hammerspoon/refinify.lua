-- Refinify for Hammerspoon - All-in-one version
-- Equivalent functionality to refinify-generic.ahk

-- ============================================================================
-- CONFIGURATION
-- ============================================================================


local scriptDir = debug.getinfo(1, "S").source:match("@?(.*/)")
local envFile = scriptDir .. ".env-secrets"
local promptFile = scriptDir .. "system-prompt-completion.md"

local config = {}

-- OpenAI Configuration (equivalent to AutoHotkey constants)
config.OPENAI_ENDPOINT = "https://api.openai.com"
config.OPENAI_API_VERSION = ""
config.OPENAI_MODEL = "gpt-4.1"
config.MAX_TOKENS = 800
config.TEMPERATURE = 0.7
config.TOP_P = 0.95
config.FREQUENCY_PENALTY = 0
config.PRESENCE_PENALTY = 0
config.CUSTOM_COMPLETION_URL = ""

-- Load system prompt from file
function config.loadSystemPrompt()
    local file = io.open(promptFile, "r")
    if not file then
        print("Refinify: Using default system prompt (file not found)")
        return "You are a helpful assistant that refines and improves text clarity and grammar."
    end
    local content = file:read("*all")
    file:close()
    print("Refinify: Loaded system prompt from " .. promptFile .. " (" .. string.len(content) .. " bytes)")
    return content
end

-- Read configuration from .env-secrets file (equivalent to LoadConfigurationFromFile function)
function config.loadConfigurationFromFile()
    local file = io.open(envFile, "r")
    if not file then
        return ""
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

    -- Load all configuration values (equivalent to Windows LoadConfigurationFromFile)
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

-- Read API key from loaded configuration (equivalent to Windows readAPIKey)
function config.readAPIKey()
    return config.loadConfigurationFromFile()
end

-- LoadConfiguration function (equivalent to Windows AutoHotkey version)
-- Checks if config file exists and API key is not empty, otherwise shows config dialog
function LoadConfiguration()
    local file = io.open(envFile, "r")
    if file then
        file:close()
        -- Reload configuration from file just in case it was edited manually
        local apiKey = config.loadConfigurationFromFile()
        if apiKey and apiKey ~= "" then
            return true
        end
    else
        -- Create empty config file if it doesn't exist
        file = io.open(envFile, "w")
        if file then
            file:write("# Refinify Configuration file\n")
            file:close()
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
    local headers = {
        ["Content-Type"] = "application/json; charset=utf-8",
        ["api-key"] = apiKey,
        ["Authorization"] = "Bearer " .. apiKey
    }

    hs.http.doAsyncRequest(completionUrl, "POST", payload, headers, function(status, body, headers)
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
                content = config.loadSystemPrompt()
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
                local errorMsg = "AI request failed: " .. error .. "\n" ..
                    "Please check your configuration and ensure the OpenAI API is accessible.\n" ..
                    "OPENAI_API_KEY: " .. (config.OPENAI_API_KEY and string.len(config.OPENAI_API_KEY) > 2 and string.sub(config.OPENAI_API_KEY, 1, 1) .. "xxx" .. string.sub(config.OPENAI_API_KEY, -1) or config.OPENAI_API_KEY or "Not set") .. "\n" ..
                    "OPENAI_ENDPOINT: " .. config.OPENAI_ENDPOINT .. "\n" ..
                    "OPENAI_API_VERSION: " .. config.OPENAI_API_VERSION .. "\n" ..
                    "OPENAI_MODEL: " .. config.OPENAI_MODEL
                hs.alert.show(errorMsg)
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
                local errorMsg = "AI request failed: " .. error .. "\n" ..
                    "Please check your configuration and ensure the OpenAI API is accessible.\n" ..
                    "OPENAI_API_KEY: " .. (config.OPENAI_API_KEY and string.len(config.OPENAI_API_KEY) > 2 and string.sub(config.OPENAI_API_KEY, 1, 1) .. "xxx" .. string.sub(config.OPENAI_API_KEY, -1) or config.OPENAI_API_KEY or "Not set") .. "\n" ..
                    "OPENAI_ENDPOINT: " .. config.OPENAI_ENDPOINT .. "\n" ..
                    "OPENAI_API_VERSION: " .. config.OPENAI_API_VERSION .. "\n" ..
                    "OPENAI_MODEL: " .. config.OPENAI_MODEL
                hs.alert.show(errorMsg)
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

    -- Create a comprehensive configuration dialog similar to Windows AHK
    local configChoices = {
        "API Key: " .. (currentApiKey ~= "" and string.sub(currentApiKey, 1, 1) .. "xxx" .. string.sub(currentApiKey, -1) or "Not set"),
        "Endpoint: " .. config.OPENAI_ENDPOINT,
        "API Version: " .. (config.OPENAI_API_VERSION ~= "" and config.OPENAI_API_VERSION or "Empty (for OpenAI)"),
        "Model: " .. config.OPENAI_MODEL,
        "Max Tokens: " .. config.MAX_TOKENS,
        "Temperature: " .. string.format("%.2f", config.TEMPERATURE),
        "Top P: " .. string.format("%.2f", config.TOP_P),
        "Frequency Penalty: " .. string.format("%.1f", config.FREQUENCY_PENALTY),
        "Presence Penalty: " .. string.format("%.1f", config.PRESENCE_PENALTY),
        "Custom URL: " .. (config.CUSTOM_COMPLETION_URL ~= "" and config.CUSTOM_COMPLETION_URL or "Not set"),
        "Edit Configuration",
        "Cancel"
    }

    -- Create a chooser for configuration options
    local chooser = hs.chooser.new(function(selected)
        if not selected then
            return false
        end

        local choice = selected.index
        if choice == 11 then -- "Edit Configuration"
            showDetailedConfigDialog()
        elseif choice == 12 then -- "Cancel"
            return false
        else
            -- Show current value for selected option
            local optionNames = {"API Key", "Endpoint", "API Version", "Model", "Max Tokens", "Temperature", "Top P", "Frequency Penalty", "Presence Penalty", "Custom URL"}
            local currentValues = {currentApiKey, config.OPENAI_ENDPOINT, config.OPENAI_API_VERSION, config.OPENAI_MODEL, tostring(config.MAX_TOKENS), string.format("%.2f", config.TEMPERATURE), string.format("%.2f", config.TOP_P), string.format("%.1f", config.FREQUENCY_PENALTY), string.format("%.1f", config.PRESENCE_PENALTY), config.CUSTOM_COMPLETION_URL}

            local button2, result = hs.dialog.textPrompt("Edit " .. optionNames[choice],
                "Current value: " .. currentValues[choice] .. "\nEnter new value:", currentValues[choice], "Save", "Cancel")

            if button2 == "Save" and result ~= "" then
                -- Update configuration
                if choice == 1 then -- API Key
                    config.OPENAI_API_KEY = result
                elseif choice == 2 then -- Endpoint
                    config.OPENAI_ENDPOINT = result
                elseif choice == 3 then -- API Version
                    config.OPENAI_API_VERSION = result
                elseif choice == 4 then -- Model
                    config.OPENAI_MODEL = result
                elseif choice == 5 then -- Max Tokens
                    config.MAX_TOKENS = tonumber(result) or config.MAX_TOKENS
                elseif choice == 6 then -- Temperature
                    config.TEMPERATURE = tonumber(result) or config.TEMPERATURE
                elseif choice == 7 then -- Top P
                    config.TOP_P = tonumber(result) or config.TOP_P
                elseif choice == 8 then -- Frequency Penalty
                    config.FREQUENCY_PENALTY = tonumber(result) or config.FREQUENCY_PENALTY
                elseif choice == 9 then -- Presence Penalty
                    config.PRESENCE_PENALTY = tonumber(result) or config.PRESENCE_PENALTY
                elseif choice == 10 then -- Custom URL
                    config.CUSTOM_COMPLETION_URL = result
                end

                saveConfiguration()
                return true
            end
        end
    end)

    -- Populate chooser with configuration choices
    local choices = {}
    for i, choice in ipairs(configChoices) do
        table.insert(choices, {text = choice, index = i})
    end

    chooser:choices(choices)
    chooser:placeholderText("Select configuration option")
    chooser:show()

    return true
end

-- Helper function to update specific configuration values
function updateConfigValue(choice, newValue)
    local optionNames = {"OPENAI_API_KEY", "OPENAI_ENDPOINT", "OPENAI_API_VERSION", "OPENAI_MODEL", "MAX_TOKENS", "TEMPERATURE", "TOP_P", "FREQUENCY_PENALTY", "PRESENCE_PENALTY", "CUSTOM_COMPLETION_URL"}
    local optionName = optionNames[choice]

    -- Validate numeric values
    if choice >= 5 and choice <= 9 then
        local numValue = tonumber(newValue)
        if not numValue then
            hs.alert.show("Error: Invalid numeric value for " .. optionName)
            return false
        end
        newValue = tostring(numValue)
    end

    -- Update the config
    if optionName == "OPENAI_API_KEY" then
        config.OPENAI_API_KEY = newValue
    elseif optionName == "OPENAI_ENDPOINT" then
        config.OPENAI_ENDPOINT = newValue
    elseif optionName == "OPENAI_API_VERSION" then
        config.OPENAI_API_VERSION = newValue
    elseif optionName == "OPENAI_MODEL" then
        config.OPENAI_MODEL = newValue
    elseif optionName == "MAX_TOKENS" then
        config.MAX_TOKENS = tonumber(newValue)
    elseif optionName == "TEMPERATURE" then
        config.TEMPERATURE = tonumber(newValue)
    elseif optionName == "TOP_P" then
        config.TOP_P = tonumber(newValue)
    elseif optionName == "FREQUENCY_PENALTY" then
        config.FREQUENCY_PENALTY = tonumber(newValue)
    elseif optionName == "PRESENCE_PENALTY" then
        config.PRESENCE_PENALTY = tonumber(newValue)
    elseif optionName == "CUSTOM_COMPLETION_URL" then
        config.CUSTOM_COMPLETION_URL = newValue
    end

    -- Save configuration
    return saveConfiguration()
end

-- Detailed configuration dialog similar to Windows AHK
function showDetailedConfigDialog()
    local currentApiKey = config.readAPIKey() or ""

    -- Create a multi-step configuration process
    local steps = {
        {title = "API Configuration",
         fields = {
             {name = "OPENAI_API_KEY", label = "[Mandatory] API Key:", value = currentApiKey, password = true},
             {name = "OPENAI_ENDPOINT", label = "[Mandatory] Endpoint URL:", value = config.OPENAI_ENDPOINT},
             {name = "OPENAI_API_VERSION", label = "[Must be empty for OpenAI] API Version:", value = config.OPENAI_API_VERSION},
             {name = "OPENAI_MODEL", label = "[Mandatory] OpenAI Model:", value = config.OPENAI_MODEL}
         }},
        {title = "Advanced Settings",
         fields = {
             {name = "CUSTOM_COMPLETION_URL", label = "Custom Completion URL:", value = config.CUSTOM_COMPLETION_URL},
             {name = "MAX_TOKENS", label = "Max Tokens:", value = tostring(config.MAX_TOKENS)},
             {name = "TEMPERATURE", label = "Temperature:", value = string.format("%.2f", config.TEMPERATURE)},
             {name = "TOP_P", label = "Top P:", value = string.format("%.2f", config.TOP_P)},
             {name = "FREQUENCY_PENALTY", label = "Frequency Penalty:", value = string.format("%.1f", config.FREQUENCY_PENALTY)},
             {name = "PRESENCE_PENALTY", label = "Presence Penalty:", value = string.format("%.1f", config.PRESENCE_PENALTY)}
         }}
    }

    local currentStep = 1

    local function showStep(stepIndex)
        if stepIndex > #steps then
            -- All steps completed, save configuration
            saveConfiguration()
            return
        end

        local step = steps[stepIndex]
        local choices = {"Next", "Previous", "Cancel"}
        if stepIndex == #steps then
            choices = {"Save", "Previous", "Cancel"}
        end

        local fieldChoices = {}
        for i, field in ipairs(step.fields) do
            local displayValue = field.value
            if field.password and field.value ~= "" then
                displayValue = string.sub(field.value, 1, 1) .. "xxx" .. string.sub(field.value, -1)
            end
            table.insert(fieldChoices, field.label .. " " .. displayValue)
        end

        local button, choice = hs.dialog.chooseFromList(fieldChoices, step.title, table.concat(choices, ", "))

        if button == "OK" and choice then
            if choice <= #step.fields then
                -- Edit field
                local field = step.fields[choice]
                local button2, result = hs.dialog.textPrompt("Edit " .. field.label,
                    "Enter new value:", field.value, "OK", "Cancel")

                if button2 == "OK" and result then
                    -- Update the field value
                    field.value = result
                    -- Update config object
                    if field.name == "OPENAI_API_KEY" then
                        config.OPENAI_API_KEY = result
                    elseif field.name == "OPENAI_ENDPOINT" then
                        config.OPENAI_ENDPOINT = result
                    elseif field.name == "OPENAI_API_VERSION" then
                        config.OPENAI_API_VERSION = result
                    elseif field.name == "OPENAI_MODEL" then
                        config.OPENAI_MODEL = result
                    elseif field.name == "CUSTOM_COMPLETION_URL" then
                        config.CUSTOM_COMPLETION_URL = result
                    elseif field.name == "MAX_TOKENS" then
                        config.MAX_TOKENS = tonumber(result) or config.MAX_TOKENS
                    elseif field.name == "TEMPERATURE" then
                        config.TEMPERATURE = tonumber(result) or config.TEMPERATURE
                    elseif field.name == "TOP_P" then
                        config.TOP_P = tonumber(result) or config.TOP_P
                    elseif field.name == "FREQUENCY_PENALTY" then
                        config.FREQUENCY_PENALTY = tonumber(result) or config.FREQUENCY_PENALTY
                    elseif field.name == "PRESENCE_PENALTY" then
                        config.PRESENCE_PENALTY = tonumber(result) or config.PRESENCE_PENALTY
                    end
                end
                -- Show the same step again with updated values
                showStep(stepIndex)
            elseif choice == #fieldChoices + 1 then -- Next/Save
                showStep(stepIndex + 1)
            elseif choice == #fieldChoices + 2 then -- Previous
                if stepIndex > 1 then
                    showStep(stepIndex - 1)
                else
                    showStep(stepIndex)
                end
            end
        end
    end

    showStep(1)
end

-- Save configuration with backup (equivalent to ConfigSave in Windows AHK)
function saveConfiguration()
    -- Create backup (equivalent to Windows FileCopy)
    local backupFile = envFile .. ".bak"
    local backupExists = io.open(envFile, "r")
    if backupExists then
        backupExists:close()
        local backupContent = io.open(envFile, "r"):read("*all")
        local backupWrite = io.open(backupFile, "w")
        if backupWrite then
            backupWrite:write(backupContent)
            backupWrite:close()
        end
    end

    -- Save new configuration
    local file = io.open(envFile, "w")
    if file then
        local envContent = "OPENAI_API_KEY=" .. (config.OPENAI_API_KEY or "") .. "\n" ..
            "OPENAI_ENDPOINT=" .. config.OPENAI_ENDPOINT .. "\n" ..
            "OPENAI_API_VERSION=" .. config.OPENAI_API_VERSION .. "\n" ..
            "OPENAI_MODEL=" .. config.OPENAI_MODEL .. "\n" ..
            "CUSTOM_COMPLETION_URL=" .. config.CUSTOM_COMPLETION_URL .. "\n" ..
            "MAX_TOKENS=" .. config.MAX_TOKENS .. "\n" ..
            "TEMPERATURE=" .. string.format("%.2f", config.TEMPERATURE) .. "\n" ..
            "TOP_P=" .. string.format("%.2f", config.TOP_P) .. "\n" ..
            "FREQUENCY_PENALTY=" .. string.format("%.1f", config.FREQUENCY_PENALTY) .. "\n" ..
            "PRESENCE_PENALTY=" .. string.format("%.1f", config.PRESENCE_PENALTY) .. "\n"

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
        local file = io.open(envFile, "r")
        if not file then
            -- Create empty config file if it doesn't exist
            file = io.open(envFile, "w")
            if file then
                file:write("# Refinify Configuration file\n")
                file:close()
            end
        else
            file:close()
        end
        showConfigDialog()
    end)

    hs.alert.show("Refinify loaded! Use Cmd+Alt+P (replace) or Cmd+Alt+R (append)")
end

-- Auto-initialize when module is loaded
refinify.init()

-- Return the module for manual initialization if needed
return refinify
