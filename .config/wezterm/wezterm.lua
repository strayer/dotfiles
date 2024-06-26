-- Pull in the wezterm API
local wezterm = require("wezterm")
local current_system_theme = require("current-system-theme")
local act = wezterm.action

local function isViProcess(pane)
  -- get_foreground_process_name On Linux, macOS and Windows,
  -- the process can be queried to determine this path. Other operating systems
  -- (notably, FreeBSD and other unix systems) are not currently supported
  return pane:get_foreground_process_name():find("n?vim") ~= nil
  -- return pane:get_title():find("n?vim") ~= nil
end

local function conditionalActivatePane(window, pane, pane_direction, vim_direction)
  if isViProcess(pane) then
    window:perform_action(
      -- This should match the keybinds you set in Neovim.
      act.SendKey({ key = vim_direction, mods = "CTRL" }),
      pane
    )
  else
    window:perform_action(act.ActivatePaneDirection(pane_direction), pane)
  end
end

local function scheme_for_appearance(appearance)
  if appearance:find("Dark") then
    return 'Tokyo Night Storm'
    -- return "Cyberdream"
  else
    return 'Tokyo Night Day'
    -- return "Cyberdream Light"
  end
end

local function get_appearance()
  if current_system_theme == "dark" then
    return "Dark"
  else
    return "Light"
  end
end

wezterm.on("ActivatePaneDirection-right", function(window, pane)
  conditionalActivatePane(window, pane, "Right", "l")
end)
wezterm.on("ActivatePaneDirection-left", function(window, pane)
  conditionalActivatePane(window, pane, "Left", "h")
end)
wezterm.on("ActivatePaneDirection-up", function(window, pane)
  conditionalActivatePane(window, pane, "Up", "k")
end)
wezterm.on("ActivatePaneDirection-down", function(window, pane)
  conditionalActivatePane(window, pane, "Down", "j")
end)

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.color_schemes = {
  ["Cyberdream"] = require("cyberdream"),
  ["Cyberdream Light"] = require("cyberdream-light"),
}

-- config.color_scheme = "Tokyo Night Storm (Gogh)"
config.color_scheme = scheme_for_appearance(get_appearance())
config.font = wezterm.font("Iosevka Term")
config.font_size = 16

config.term = "wezterm"

config.send_composed_key_when_left_alt_is_pressed = false

config.keys = {
  { key = "h", mods = "CTRL", action = act.EmitEvent("ActivatePaneDirection-left") },
  { key = "j", mods = "CTRL", action = act.EmitEvent("ActivatePaneDirection-down") },
  { key = "k", mods = "CTRL", action = act.EmitEvent("ActivatePaneDirection-up") },
  { key = "l", mods = "CTRL", action = act.EmitEvent("ActivatePaneDirection-right") },
  {
    key = "Enter",
    mods = "SUPER",
    action = act.SplitPane({
      direction = "Right",
      size = { Percent = 50 },
    }),
  },
  {
    key = "Enter",
    mods = "SUPER|SHIFT",
    action = act.SplitPane({
      direction = "Down",
      size = { Percent = 50 },
    }),
  },
}

-- and finally, return the configuration to wezterm
return config
