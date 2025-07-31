-- items/chevron.lua - Left side decorator

local icons = require("lib.icons")
local colors = require("lib.colors")
local settings = require("lib.settings")

-- Add chevron decorator to left side
local chevron = sbar.add("item", "chevron", {
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

    if current_theme_name == "light" then
      -- Swap colors for light mode
      background_color = label_color
      label_color = theme_colors.item_background
    end

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
  -- On personal machines, just show the icon
  chevron:set({
    icon = {
      string = icons.system.chevron,
      font = {
        size = 20,
      },
    },
    label = {
      drawing = false,
    },
    background = {
      drawing = false,
    },
  })
end
