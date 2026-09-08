-- bar.lua - Bar appearance configuration

local colors = require("lib.colors")
local settings = require("lib.settings")

-- Add system theme change event
sbar.add("event", "theme_change", "AppleInterfaceThemeChangedNotification")

-- Configure the bar appearance (transparent strip; islands paint themselves)
sbar.bar({
  position = "top",
  height = settings.layout.bar_height,
  notch_display_height = settings.layout.notch_bar_height,
  margin = 0,
  y_offset = settings.layout.bar_y_offset,
  corner_radius = 0,
  blur_radius = 0,
  color = colors.transparent,
  padding_left = settings.layout.bar_padding_h,
  padding_right = settings.layout.bar_padding_h,
})

-- Size the notch-display bar strip so pills center between the display edge
-- and the window tops: macOS reserves the menu-bar strip whose POINT height
-- varies with the scaling mode (38 at "More Space" in laptop mode, 32 at
-- default scaling when the internal display is a secondary monitor). Rift
-- reports it as the built-in display's frame origin and starts windows
-- notch_window_gap below it - the bar strip extends to exactly that line,
-- so centering within the strip centers between edge and windows. The
-- static notch_bar_height above is only the fallback until this async sync
-- lands (and if rift isn't running).
--
-- Pills adapt too: their height clamps to the smallest strip present minus
-- pill_strip_margin (heights are global in SketchyBar, so a small strip
-- slims ALL pills rather than gluing the internal ones to its edges). A
-- change re-triggers theme_colors_updated, which every island and item
-- already uses to restyle.
local RIFT_CLI = (os.getenv("HOME") or "") .. "/.bin/rift-cli"

local function sync_notch_height()
  sbar.exec(RIFT_CLI .. " query displays", function(displays)
    if type(displays) ~= "table" then
      return
    end

    local smallest_strip = settings.layout.bar_height
    for _, display in ipairs(displays) do
      local origin_y = display.frame and display.frame.origin and display.frame.origin.y
      if display.name == "Built-in Retina Display" and origin_y and origin_y > 0 then
        local strip = origin_y + settings.layout.notch_window_gap
        sbar.bar({ notch_display_height = strip })
        smallest_strip = math.min(smallest_strip, strip)
      end
    end

    local pill_height =
      math.min(settings.layout.pill_height, smallest_strip - settings.layout.pill_strip_margin)
    if pill_height ~= settings.layout.current_pill_height then
      settings.layout.current_pill_height = pill_height
      sbar.trigger("theme_colors_updated")
    end
  end)
end

local notch_handler = sbar.add("item", "notch_height_handler", { drawing = false, updates = true })
notch_handler:subscribe({ "display_change", "system_woke" }, sync_notch_height)
sync_notch_height()
