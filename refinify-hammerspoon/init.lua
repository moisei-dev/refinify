-- Refinify for macOS using Hammerspoon
-- Main entry point
-- Place this file in ~/.hammerspoon/ and rename to init.lua

local refinify = require('refinify')

-- Initialize the module
refinify.init()

-- Optional: Show a notification when Hammerspoon starts
hs.notify.new({title="Refinify", informativeText="Loaded successfully. Use Cmd+Alt+R or Cmd+Alt+T to refine text."}):send()
