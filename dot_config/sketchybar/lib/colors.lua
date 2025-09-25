-- colors.lua - Dynamic Catppuccin theme system for SBarLua

local M = {}

-- Catppuccin Latte (Light theme)
local catppuccin_latte = {
  base = 0xFFEFF1F5,
  text = 0xFF4C4F69,
  pink = 0xFFEA76CB,
  mauve = 0xFF8839EF,
  red = 0xFFD20F39,
  maroon = 0xFFE64553,
  peach = 0xFFFE640B,
  yellow = 0xFFDF8E1D,
  green = 0xFF40A02B,
  teal = 0xFF179299,
  sky = 0xFF04A5E5,
  sapphire = 0xFF209FB5,
  blue = 0xFF1E66F5,
  lavender = 0xFF7287FD,
  subtext1 = 0xFF5C5F77,
  subtext0 = 0xFF6C6F85,
  overlay2 = 0xFF7C7F93,
  overlay1 = 0xFF8C8FA1,
  overlay0 = 0xFF9CA0B0,
  surface2 = 0xFFACB0BE,
  surface1 = 0xFFBCC0CC,
  surface0 = 0xFFCCD0DA,
  mantle = 0xFFE6E9EF,
  crust = 0xFFDCE0E8,
}

-- Catppuccin Frappé (Dark theme alternative)
local catppuccin_frappe = {
  base = 0xFF303446,
  text = 0xFFC6D0F5,
  pink = 0xFFF4B8E4,
  mauve = 0xFFCA9EE6,
  red = 0xFFE78284,
  maroon = 0xFFEA999C,
  peach = 0xFFEF9F76,
  yellow = 0xFFE5C890,
  green = 0xFFA6D189,
  teal = 0xFF81C8BE,
  sky = 0xFF99D1DB,
  sapphire = 0xFF85C1DC,
  blue = 0xFF8CAAEE,
  lavender = 0xFFBABBF1,
  subtext1 = 0xFFB5BFE2,
  subtext0 = 0xFFA5ADCE,
  overlay2 = 0xFF949CBB,
  overlay1 = 0xFF838BA7,
  overlay0 = 0xFF737994,
  surface2 = 0xFF626880,
  surface1 = 0xFF51576D,
  surface0 = 0xFF414559,
  mantle = 0xFF292C3C,
  crust = 0xFF232634,
}

-- Catppuccin Macchiato (Dark theme alternative)
local catppuccin_macchiato = {
  base = 0xFF24273A,
  text = 0xFFCAD3F5,
  pink = 0xFFF5BDE6,
  mauve = 0xFFC6A0F6,
  red = 0xFFED8796,
  maroon = 0xFFEE99A0,
  peach = 0xFFF5A97F,
  yellow = 0xFFEED49F,
  green = 0xFFA6DA95,
  teal = 0xFF8BD5CA,
  sky = 0xFF91D7E3,
  sapphire = 0xFF7DC4E4,
  blue = 0xFF8AADF4,
  lavender = 0xFFB7BDF8,
  subtext1 = 0xFFB8C0E0,
  subtext0 = 0xFFA5ADCB,
  overlay2 = 0xFF939AB7,
  overlay1 = 0xFF8087A2,
  overlay0 = 0xFF6E738D,
  surface2 = 0xFF5B6078,
  surface1 = 0xFF494D64,
  surface0 = 0xFF363A4F,
  mantle = 0xFF1E2030,
  crust = 0xFF181926,
}

-- Catppuccin Mocha (Default dark theme)
local catppuccin_mocha = {
  base = 0xFF1E1E2E,
  text = 0xFFCDD6F4,
  pink = 0xFFF5C2E7,
  mauve = 0xFFCBA6F7,
  red = 0xFFF38BA8,
  maroon = 0xFFEBA0AC,
  peach = 0xFFFAB387,
  yellow = 0xFFF9E2AF,
  green = 0xFFA6E3A1,
  teal = 0xFF94E2D5,
  sky = 0xFF89DCEB,
  sapphire = 0xFF74C7EC,
  blue = 0xFF89B4FA,
  lavender = 0xFFB4BEFE,
  subtext1 = 0xFFBAC2DE,
  subtext0 = 0xFFA6ADC8,
  overlay2 = 0xFF9399B2,
  overlay1 = 0xFF7F849C,
  overlay0 = 0xFF6C7086,
  surface2 = 0xFF585B70,
  surface1 = 0xFF45475A,
  surface0 = 0xFF313244,
  mantle = 0xFF181825,
  crust = 0xFF11111B,
}

-- Global colors
M.white = 0xffffffff
M.transparent = 0x00000000

-- Helper function to set alpha channel for colors
function M.with_alpha(color, alpha)
  -- alpha should be between 0.0 and 1.0
  -- Convert alpha to 8-bit value (0-255)
  local alpha_8bit = math.floor(alpha * 255)
  -- Extract RGB components and combine with new alpha
  local rgb = color & 0x00FFFFFF
  return (alpha_8bit << 24) | rgb
end

-- Current theme cache
local current_theme = "dark" -- Default to dark theme
local theme_colors = {}

-- Function to detect system theme synchronously
local function detect_system_theme_sync()
  local handle = io.popen("defaults read -g AppleInterfaceStyle 2>/dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    if result and result:match("Dark") then
      current_theme = "dark"
    else
      current_theme = "light"
    end
  end
end

-- Function to update theme colors based on current system theme
function M.update_theme_colors()
  -- Re-detect the current theme first
  detect_system_theme_sync()

  if current_theme == "light" then
    -- Light theme colors (Catppuccin Latte)
    theme_colors = {
      warning = catppuccin_latte.peach,
      critical = catppuccin_latte.red,
      bar_background = M.with_alpha(0x000000, 0.3),
      item_background = M.transparent,
      highlighted_item_background = M.with_alpha(catppuccin_latte.surface0, 0.8),
      item_primary = catppuccin_latte.crust,
      highlighted_item_primary = catppuccin_latte.blue,
    }
  else
    -- Dark theme colors (Catppuccin Mocha)
    theme_colors = {
      warning = catppuccin_mocha.peach,
      critical = catppuccin_mocha.red,
      bar_background = M.transparent,
      item_background = M.transparent,
      highlighted_item_background = M.with_alpha(catppuccin_mocha.surface0, 0.7),
      item_primary = catppuccin_mocha.subtext1,
      highlighted_item_primary = catppuccin_mocha.text,
    }
  end
end

-- Function to get current theme colors
function M.get_colors()
  if not theme_colors or not theme_colors.item_primary then
    M.update_theme_colors()
  end
  return theme_colors
end

-- Function to get specific palette
function M.get_palette(palette_name)
  if palette_name == "latte" then
    return catppuccin_latte
  elseif palette_name == "frappe" then
    return catppuccin_frappe
  elseif palette_name == "macchiato" then
    return catppuccin_macchiato
  elseif palette_name == "mocha" then
    return catppuccin_mocha
  else
    return catppuccin_mocha -- Default fallback
  end
end

-- Function to get current theme name
function M.get_current_theme()
  return current_theme
end

-- Helper function to get standard item color configuration
function M.get_item_colors(options)
  local current_theme_colors = M.get_colors()
  local config = {
    icon = { color = current_theme_colors.item_primary },
    label = { color = current_theme_colors.item_primary },
    background = { color = current_theme_colors.item_background },
  }

  -- Handle semantic states
  if options then
    if options.state == "critical" then
      config.icon.color = current_theme_colors.critical
      config.label.color = current_theme_colors.critical
    elseif options.state == "warning" then
      config.icon.color = current_theme_colors.warning
      config.label.color = current_theme_colors.warning
    elseif options.state == "highlighted" then
      config.icon.color = current_theme_colors.highlighted_item_primary
      config.label.color = current_theme_colors.highlighted_item_primary
      config.background.color = current_theme_colors.highlighted_item_background
    end
  end

  return config
end

-- Initialize theme detection synchronously
detect_system_theme_sync()
M.update_theme_colors()

return M
