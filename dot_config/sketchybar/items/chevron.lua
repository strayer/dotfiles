-- items/chevron.lua - Left side decorator

local icons = require("lib.icons")
local colors = require("lib.colors")
local settings = require("lib.settings")

-- Add chevron decorator to left side
local chevron = sbar.add("item", "left.chevron", {
  position = "left",
})

if settings.is_work_machine then
  -- On the work machine, display a rotating value with a specific color

  -- Seed the random number generator
  math.randomseed(os.time())

  local values = {
    { text = "verantwortung", color_name = "blue" },
    { text = "zusammenhalt", color_name = "green" },
    { text = "kundenliebe", color_name = "red" },
    { text = "neugier", color_name = "peach" }, -- Using peach as a stand-in for orange
    { text = "freude", color_name = "yellow" },
  }

  local function update_chevron_label()
    -- Select a random value from the table
    local random_entry = values[math.random(#values)]

    -- Get the current color palettes and theme name
    local current_theme_name = colors.get_current_theme()
    local palette_name = (current_theme_name == "light") and "latte" or "mocha"
    local theme_palette = colors.get_palette(palette_name)
    local theme_colors = colors.get_colors()

    -- Determine the color for the label's foreground
    local label_color = theme_palette[random_entry.color_name]
    local background_color = theme_colors.item_background

    -- Update the chevron item
    chevron:set({
      icon = {
        string = icons.system.chevron,
        color = label_color,
        y_offset = -1,
        font = {
          size = 16,
        },
      },
      label = {
        string = random_entry.text,
        color = label_color,
        drawing = true,
      },
      background = {
        color = background_color,
        drawing = true,
      },
    })
  end

  -- Configure the item for periodic updates
  chevron:set({
    update_freq = 1800, -- 30 minutes
    updates = true,
  })

  -- Subscribe to events
  chevron:subscribe({ "routine", "theme_colors_updated", "mouse.clicked" }, update_chevron_label)

  -- Initial update
  update_chevron_label()
else
  -- On personal machines, show hostname with background and icon

  -- Hostname override table for special display names
  local hostname_overrides = {
    ["yobuko"] = "よぶこ",
    -- Future overrides can be added here
  }

  -- Get display name (override or actual hostname)
  local display_name = hostname_overrides[settings.hostname] or settings.hostname

  -- Get current theme colors
  local theme_colors = colors.get_colors()
  local mocha_palette = colors.get_palette("mocha")

  -- Use consistent mauve color from mocha palette for both themes
  local label_color = mocha_palette.mauve

  chevron:set({
    icon = {
      string = icons.system.chevron,
      color = label_color,
      y_offset = -1,
      font = {
        size = 16,
      },
    },
    label = {
      string = display_name,
      color = label_color,
      drawing = true,
    },
    background = {
      color = theme_colors.item_background,
      drawing = true,
    },
  })

  -- Subscribe to theme updates to maintain color consistency
  chevron:subscribe("theme_colors_updated", function()
    local updated_theme_colors = colors.get_colors()
    local updated_mocha_palette = colors.get_palette("mocha")
    local updated_label_color = updated_mocha_palette.mauve

    chevron:set({
      icon = { color = updated_label_color },
      label = { color = updated_label_color },
      background = { color = updated_theme_colors.item_background },
    })
  end)
end
