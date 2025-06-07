-- Refinify Module for Hammerspoon
-- Equivalent functionality to refinify-generic.ahk

local refinify = {}
local config = require('config')
local openai = require('openai')

-- Initialize keyboard shortcuts and setup
function refinify.init()
    -- Cmd+Alt+R: Append refined message to original message
    hs.hotkey.bind({"cmd", "alt"}, "R", function()
        refinify.refineAndAppend()
    end)

    -- Cmd+Alt+T: Replace original message with refined message
    hs.hotkey.bind({"cmd", "alt"}, "T", function()
        refinify.refineAndReplace()
    end)

    print("Refinify initialized with hotkeys Cmd+Alt+R and Cmd+Alt+T")
end

-- Append refined message to original message (equivalent to Ctrl+Alt+R)
function refinify.refineAndAppend()
    local originalText = refinify.getSelectedText()
    if not originalText or originalText == "" then
        hs.alert.show("No text found to refine")
        return
    end

    -- Show progress indicator
    local modal = hs.alert.show("Refining message...", true)

    openai.refineMessage(originalText, function(refinedText, error)
        hs.alert.closeAll()

        if error then
            hs.alert.show("Error: " .. error)
            return
        end

        if refinedText then
            local combinedText = originalText .. "\n\n" .. refinedText .. "\n"
            refinify.replaceText(combinedText)
        else
            hs.alert.show("Failed to refine message")
        end
    end)
end

-- Replace original message with refined message (equivalent to Ctrl+Alt+T)
function refinify.refineAndReplace()
    local originalText = refinify.getSelectedText()
    if not originalText or originalText == "" then
        hs.alert.show("No text found to refine")
        return
    end

    -- Show progress indicator
    local modal = hs.alert.show("Refining message...", true)

    openai.refineMessage(originalText, function(refinedText, error)
        hs.alert.closeAll()

        if error then
            hs.alert.show("Error: " .. error)
            return
        end

        if refinedText then
            refinify.replaceText(refinedText)
        else
            hs.alert.show("Failed to refine message")
        end
    end)
end

-- Get selected text from the current application
function refinify.getSelectedText()
    -- Save current clipboard
    local originalClipboard = hs.pasteboard.getContents()

    -- Clear clipboard
    hs.pasteboard.setContents("")

    -- Select all text and copy
    hs.eventtap.keyStroke({"cmd"}, "a")
    hs.timer.usleep(100000) -- Wait 100ms
    hs.eventtap.keyStroke({"cmd"}, "c")
    hs.timer.usleep(200000) -- Wait 200ms for copy to complete

    -- Get the copied text
    local text = hs.pasteboard.getContents()

    -- Restore original clipboard after a delay
    hs.timer.doAfter(0.5, function()
        if originalClipboard then
            hs.pasteboard.setContents(originalClipboard)
        end
    end)

    return text
end

-- Replace text in the current application
function refinify.replaceText(newText)
    if not newText then return end

    -- Save current clipboard
    local originalClipboard = hs.pasteboard.getContents()

    -- Put new text in clipboard
    hs.pasteboard.setContents(newText)

    -- Paste the new text
    hs.eventtap.keyStroke({"cmd"}, "v")

    -- Restore original clipboard after paste completes
    hs.timer.doAfter(0.5, function()
        if originalClipboard then
            hs.pasteboard.setContents(originalClipboard)
        end
    end)
end

-- Clean message by removing empty lines (equivalent to removeEmptyLines function)
function refinify.cleanMessage(text)
    if not text then return "" end

    local lines = {}
    for line in text:gmatch("[^\r\n]+") do
        if line:match("%S") then -- If line contains non-whitespace characters
            table.insert(lines, line)
        end
    end

    return table.concat(lines, "\n")
end

return refinify
