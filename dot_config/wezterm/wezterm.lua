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
    return "Tokyo Night Storm"
  else
    return "Catppuccin Latte"
  end
end

local function get_appearance()
  if current_system_theme == "dark" then
    return "Dark"
  else
    return "Light"
  end
end

local function get_tab_bar_colors()
  if current_system_theme == "dark" then
    -- Tokyo Night Storm
    -- https://github.com/folke/tokyonight.nvim/blob/main/extras/wezterm/tokyonight_storm.toml
    return {
      background = "#24283b",
      inactive_tab_edge = "#1f2335",
      active_tab = {
        bg_color = "#7aa2f7",
        fg_color = "#1f2335",
      },
      inactive_tab = {
        bg_color = "#292e42",
        fg_color = "#545c7e",
      },
      inactive_tab_hover = {
        bg_color = "#292e42",
        fg_color = "#7aa2f7",
      },
      new_tab = {
        bg_color = "#24283b",
        fg_color = "#7aa2f7",
      },
      new_tab_hover = {
        bg_color = "#24283b",
        fg_color = "#7aa2f7",
      },
    }
  else
    -- Catppuccin Latte
    -- https://github.com/catppuccin/wezterm/blob/main/plugin/init.lua
    return {
      background = "#dce0e8", -- crust
      inactive_tab_edge = "#ccd0da", -- surface0
      active_tab = {
        bg_color = "#8839ef", -- mauve (accent)
        fg_color = "#dce0e8", -- crust
      },
      inactive_tab = {
        bg_color = "#e6e9ef", -- mantle
        fg_color = "#4c4f69", -- text
      },
      inactive_tab_hover = {
        bg_color = "#eff1f5", -- base
        fg_color = "#4c4f69", -- text
      },
      new_tab = {
        bg_color = "#ccd0da", -- surface0
        fg_color = "#4c4f69", -- text
      },
      new_tab_hover = {
        bg_color = "#bcc0cc", -- surface1
        fg_color = "#4c4f69", -- text
      },
    }
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

local function segments_for_right_status()
  return {
    wezterm.strftime("%F %H:%M"),
    wezterm.hostname(),
  }
end

wezterm.on("update-status", function(window, _)
  local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
  local segments = segments_for_right_status()

  local color_scheme = window:effective_config().resolved_palette
  -- Note the use of wezterm.color.parse here, this returns
  -- a Color object, which comes with functionality for lightening
  -- or darkening the colour (amongst other things).
  local bg = wezterm.color.parse(color_scheme.background)
  local fg = color_scheme.foreground

  -- Each powerline segment is going to be coloured progressively
  -- darker/lighter depending on whether we're on a dark/light colour
  -- scheme. Let's establish the "from" and "to" bounds of our gradient.
  local gradient_to = bg
  local gradient_from
  if current_system_theme == "dark" then
    gradient_from = gradient_to:lighten(0.2)
  else
    gradient_from = gradient_to:darken(0.2)
  end

  -- Yes, WezTerm supports creating gradients, because why not?! Although
  -- they'd usually be used for setting high fidelity gradients on your terminal's
  -- background, we'll use them here to give us a sample of the powerline segment
  -- colours we need.
  local gradient = wezterm.color.gradient(
    {
      orientation = "Horizontal",
      colors = { gradient_from, gradient_to },
    },
    #segments -- only gives us as many colours as we have segments.
  )

  -- We'll build up the elements to send to wezterm.format in this table.
  local elements = {}

  for i, seg in ipairs(segments) do
    local is_first = i == 1

    if is_first then
      table.insert(elements, { Background = { Color = "none" } })
    end
    table.insert(elements, { Foreground = { Color = gradient[i] } })
    table.insert(elements, { Text = SOLID_LEFT_ARROW })

    table.insert(elements, { Foreground = { Color = fg } })
    table.insert(elements, { Background = { Color = gradient[i] } })
    table.insert(elements, { Text = " " .. seg .. " " })
  end

  window:set_right_status(wezterm.format(elements))
end)

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- config.color_scheme = "Tokyo Night Storm (Gogh)"
config.color_scheme = scheme_for_appearance(get_appearance())
-- config.font = wezterm.font("Iosevka Term")
config.font = wezterm.font_with_fallback({
  "PragmataPro",
  { family = "Symbols Nerd Font Mono", scale = 0.8 },
})
config.font_size = 16

config.term = "wezterm"

config.max_fps = 120

-- Removes the title bar, leaving only the tab bar. Keeps
-- the ability to resize by dragging the window's edges.
-- On macOS, 'RESIZE|INTEGRATED_BUTTONS' also looks nice if
-- you want to keep the window controls visible and integrate
-- them into the tab bar.
config.window_decorations = "RESIZE|INTEGRATED_BUTTONS"

-- Sets the font for the window frame (tab bar)
local tab_colors = get_tab_bar_colors()
config.window_frame = {
  -- Berkeley Mono for me again, though an idea could be to try a
  -- serif font here instead of monospace for a nicer look?
  font = wezterm.font({ family = "Berkeley Mono", weight = "Bold" }),
  font_size = 12,
  -- The overall background color of the tab bar when the window is focused
  active_titlebar_bg = tab_colors.background,
  -- The overall background color of the tab bar when the window is not focused
  inactive_titlebar_bg = tab_colors.background,
}
config.colors = {
  tab_bar = tab_colors,
}

config.front_end = "WebGpu"

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
  { key = "Enter", mods = "SHIFT", action = wezterm.action.SendString("\n") },
  {
    key = "r",
    mods = "CMD|SHIFT",
    action = wezterm.action.ReloadConfiguration,
  },
}

-- and finally, return the configuration to wezterm
return config
