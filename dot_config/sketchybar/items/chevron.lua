-- items/chevron.lua - Left side decorator (single-item island)

local icons = require("lib.icons")
local colors = require("lib.colors")
local settings = require("lib.settings")
local brackets = require("items.brackets")

-- Add chevron decorator to left side
local chevron = sbar.add("item", "left.chevron", {
  position = "left",
  -- Single-item island: unlike brackets, the pill (item background) excludes
  -- item paddings, so the gap-side padding would stack onto the island gap.
  -- Keep only the screen-edge side.
  padding_left = 5,
  padding_right = 0,
  -- wider inner paddings keep the content off this island's rounded ends
  icon = { padding_left = 12 },
  label = { padding_right = 12 },
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

    -- Determine the color for the label's foreground
    local label_color = theme_palette[random_entry.color_name]

    -- Update the chevron item (its own island)
    chevron:set({
      icon = {
        string = icons.system.chevron,
        color = label_color,
        y_offset = 0, -- default +1 lift minus 1 for this tall glyph
        font = {
          size = 16,
        },
      },
      label = {
        string = random_entry.text,
        color = label_color,
        drawing = true,
      },
      background = brackets.island_background(),
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

  -- Use the theme-aware chevron accent (mauve in both palettes)
  local label_color = theme_colors.accents.chevron

  chevron:set({
    icon = {
      string = icons.system.chevron,
      color = label_color,
      y_offset = 0, -- default +1 lift minus 1 for this tall glyph
      font = {
        size = 16,
      },
    },
    label = {
      string = display_name,
      color = label_color,
      drawing = true,
    },
    background = brackets.island_background(),
  })

  -- Subscribe to theme updates to maintain color consistency
  chevron:subscribe("theme_colors_updated", function()
    local updated_theme_colors = colors.get_colors()
    local updated_label_color = updated_theme_colors.accents.chevron

    chevron:set({
      icon = { color = updated_label_color },
      label = { color = updated_label_color },
      background = brackets.island_background(),
    })
  end)
end
