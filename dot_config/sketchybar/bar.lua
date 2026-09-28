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
-- default scaling when the internal display is a secondary monitor). Rift's
-- usable frame for the built-in display starts below that strip, and rift
-- starts windows notch_window_gap below the frame. Both frames are in
-- global coordinates, so the strip height is the built-in display's usable
-- frame origin (rift) minus its full-bounds origin (SketchyBar) - NOT the
-- raw rift origin, which is only the strip when the built-in display is
-- the primary one at (0, 0); arranged below an external display its origin
-- is that display's height plus the strip. The bar strip extends to exactly
-- the window line, so centering within the strip centers between edge and
-- windows. The static notch_bar_height above is only the fallback until
-- this async sync lands (and if rift isn't running).
--
-- Pills adapt too: their height clamps to the smallest strip present minus
-- pill_strip_margin (heights are global in SketchyBar, so a small strip
-- slims ALL pills rather than gluing the internal ones to its edges). A
-- change re-triggers theme_colors_updated, which every island and item
-- already uses to restyle.
local RIFT_CLI = (os.getenv("HOME") or "") .. "/.bin/rift-cli"
local BUILTIN_DISPLAY_NAME = "Built-in Retina Display"

local function apply_notch_strip(strip)
  local smallest_strip = settings.layout.bar_height
  if strip then
    sbar.bar({ notch_display_height = strip })
    smallest_strip = math.min(smallest_strip, strip)
  end

  local pill_height = math.min(settings.layout.pill_height, smallest_strip - settings.layout.pill_strip_margin)
  if pill_height ~= settings.layout.current_pill_height then
    settings.layout.current_pill_height = pill_height
    sbar.trigger("theme_colors_updated")
  end
end

local function sync_notch_height()
  sbar.exec("sketchybar --query displays", function(bounds_list)
    if type(bounds_list) ~= "table" then
      return
    end

    local bounds_by_uuid = {}
    for _, bounds in ipairs(bounds_list) do
      if bounds.UUID and bounds.frame then
        bounds_by_uuid[bounds.UUID] = bounds.frame
      end
    end

    sbar.exec(RIFT_CLI .. " query displays", function(displays)
      if type(displays) ~= "table" then
        return
      end

      local strip
      for _, display in ipairs(displays) do
        local usable_y = display.frame and display.frame.origin and display.frame.origin.y
        local bounds = display.uuid and bounds_by_uuid[display.uuid]
        if display.name == BUILTIN_DISPLAY_NAME and usable_y and bounds and bounds.y then
          local reserved = usable_y - bounds.y
          if reserved > 0 then
            strip = reserved + settings.layout.notch_window_gap
          end
        end
      end

      apply_notch_strip(strip)
    end)
  end)
end

local notch_handler = sbar.add("item", "notch_height_handler", { drawing = false, updates = true })
notch_handler:subscribe({ "display_change", "system_woke" }, sync_notch_height)
sync_notch_height()
