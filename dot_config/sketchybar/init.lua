-- init.lua - Main entry point for SBarLua configuration

-- Detect running window manager by process
local function detect_wm()
  local checks = {
    { name = "omniwm", pattern = "OmniWM.app/Contents/MacOS/OmniWM" },
    { name = "rift", pattern = "rift" },
  }
  for _, wm in ipairs(checks) do
    local handle = io.popen("pgrep -f '" .. wm.pattern .. "' >/dev/null 2>&1 && echo y")
    if handle then
      local result = handle:read("*a")
      handle:close()
      if result and result:match("y") then
        return wm.name
      end
    end
  end
  return nil
end

local settings = require("lib.settings")
settings.window_manager = detect_wm()

-- Load core configuration modules
require("bar") -- Bar appearance configuration
require("default") -- Default item styling
require("items") -- All bar items
