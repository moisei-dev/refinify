-- OpenAI API client for Hammerspoon
-- Equivalent to the OpenAI API functionality in refinify-generic.ahk

local openai = {}
local config = require('config')

-- Make HTTP request to OpenAI API (equivalent to callOpenAIAPI function)
function openai.refineMessage(userMessage, callback)
    local apiKey = config.readAPIKey()
    if not apiKey then
        callback(nil, "API key not found. Please create ~/.env-secrets with OPENAI_API_KEY")
        return
    end

    local payload = openai.constructPayload(userMessage)
    local url = config.OPENAI_ENDPOINT .. "/openai/deployments/" .. config.OPENAI_MODEL .. "/chat/completions?api-version=" .. config.OPENAI_API_VERSION

    -- Make HTTP request
    hs.http.doAsyncRequest(url, "POST", payload, {
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
                        text = config.SYSTEM_PROMPT
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

return openai
