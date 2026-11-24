-- items/volume.lua - Volume display with Unicode progress bar and an audio
-- device selector popup
--
-- Hovering opens a popup listing the output and input devices; the current
-- one of each kind is checked, clicking a row makes that device the default.
-- The popup needs SwitchAudioSource (Homebrew switchaudio-osx); without it
-- the item only shows the volume.
--
-- The device list is read when the popup opens, after a click, and on
-- volume_change while it is open: SketchyBar fires volume_change when the
-- default output device changes, but has no event for input devices.

local icons = require("lib.icons")
local colors = require("lib.colors")
local utils = require("lib.utils")

local SWITCH_AUDIO_SOURCE = "/opt/homebrew/bin/SwitchAudioSource"
-- Popup rows are created once per kind; devices beyond that are not listed
local MAX_DEVICES = 8
local KINDS = { "output", "input" }
local KIND_TITLES = { output = "Output", input = "Input" }
local ROW_ICON_WIDTH = 24

local has_switcher = false
do
  local file = io.open(SWITCH_AUDIO_SOURCE, "r")
  if file then
    file:close()
    has_switcher = true
  end
end

-- Add volume item to right side
local volume = sbar.add("item", "right.volume", {
  position = "right",
  icon = {
    padding_left = 5,
  },
  popup = {
    align = "center",
    -- same surface as the bar pills; re-applied on theme changes
    background = {
      color = colors.get_colors().pill_background,
      border_color = colors.get_colors().pill_border,
      border_width = 1,
      corner_radius = 9,
    },
    blur_radius = 30,
    -- 0, not the 2 of the read-only popups: the pointer has to travel from
    -- the item into the popup, and any gap in between closes it (QUIRKS.md)
    y_offset = 0,
    height = 26, -- row height; unset it falls back to the bar height and rows look double-spaced
  },
})

-- Handle volume change events (like original shell script)
local function handle_volume_change(env)
  local volume_level = tonumber(env.INFO)
  if not volume_level then
    return
  end

  -- Determine volume icon based on volume level (like original shell script)
  local volume_icon
  if volume_level >= 60 then
    volume_icon = icons.system.volume.high
  elseif volume_level >= 30 then
    volume_icon = icons.system.volume.medium
  elseif volume_level >= 1 then
    volume_icon = icons.system.volume.low
  else -- volume_level == 0
    volume_icon = icons.system.volume.muted
  end

  -- Generate progress bar or empty label (like original shell script)
  local bar_label = ""
  if volume_level > 0 then
    local progress_bar = utils.generate_unicode_bar(volume_level, 8)
    bar_label = progress_bar .. " " .. volume_level .. "%"
  end

  -- Set icon and label with appropriate padding
  local config = colors.get_item_colors({ accent = "volume" })

  if bar_label == "" then
    -- No label - extra icon padding
    utils.merge_tables(config, {
      icon = {
        string = volume_icon,
        padding_right = 7,
      },
      label = {
        drawing = false,
      },
    })
  else
    -- Has label - normal icon padding
    utils.merge_tables(config, {
      icon = {
        string = volume_icon,
        padding_right = 4,
      },
      label = {
        string = bar_label,
        drawing = true,
      },
    })
  end

  volume:set(config)
end

-- Device selector popup ------------------------------------------------------

-- Per kind: a header row and MAX_DEVICES device rows. Popup order is creation
-- order, so both kinds are created up front and unused rows are hidden.
local headers = {}
local device_rows = { output = {}, input = {} }
-- Devices currently shown, per kind: { { id = "86", name = "…" }, … }
local devices = { output = {}, input = {} }
local current_id = {}
local hovered_row = nil
local popup_open = false

-- All device labels get the width of the widest one, so the hover highlight
-- spans the popup instead of ending after each name. SketchyBar has no
-- "fill the popup" setting and Lua cannot measure text, so the widths are
-- read back from the rendered rows once per device name.
local label_widths = {}

-- Widest label among the listed devices; nil while one is unmeasured
local function shared_label_width()
  local widest = nil
  for _, kind in ipairs(KINDS) do
    for _, device in ipairs(devices[kind]) do
      local width = label_widths[device.name]
      if not width then
        return nil
      end
      widest = math.max(widest or 0, width)
    end
  end
  return widest
end

-- Needs the popup on screen and the labels at their natural width: hidden
-- rows report a 1pt placeholder rect
local function measure_labels()
  for _, kind in ipairs(KINDS) do
    for index, device in ipairs(devices[kind]) do
      if not label_widths[device.name] then
        local info = device_rows[kind][index]:query()
        local row_width = 0
        for _, rect in pairs(type(info) == "table" and info.bounding_rects or {}) do
          row_width = math.max(row_width, tonumber(rect.size and rect.size[1]) or 0)
        end
        if row_width > ROW_ICON_WIDTH + 1 then
          label_widths[device.name] = row_width - ROW_ICON_WIDTH
        end
      end
    end
  end
end

local function row_style(kind, index)
  local theme = colors.get_colors()
  local device = devices[kind][index]
  local row = device_rows[kind][index]
  local is_current = device ~= nil and device.id == current_id[kind]
  return {
    drawing = device ~= nil,
    icon = {
      string = is_current and icons.system.audio.current or "",
      color = theme.accents.volume,
    },
    label = {
      string = device and device.name or "",
      color = is_current and theme.highlighted_item_primary or theme.item_primary,
    },
    background = {
      color = row == hovered_row and theme.highlighted_item_background or colors.transparent,
    },
  }
end

local function render_popup()
  local theme = colors.get_colors()
  volume:set({
    popup = {
      background = {
        color = theme.pill_background,
        border_color = theme.pill_border,
      },
    },
  })
  for _, kind in ipairs(KINDS) do
    headers[kind]:set({
      drawing = #devices[kind] > 0,
      icon = { color = theme.item_muted },
      label = { color = theme.item_muted },
    })
    for index, row in ipairs(device_rows[kind]) do
      row:set(row_style(kind, index))
    end
  end

  -- Label widths go out in a second command, after the names above:
  -- `width = "dynamic"` pins the label to the natural width of the string it
  -- has at that moment (QUIRKS.md), which is what measure_labels() reads.
  local function set_label_widths(width)
    for _, kind in ipairs(KINDS) do
      for index in ipairs(devices[kind]) do
        device_rows[kind][index]:set({ label = { width = width } })
      end
    end
  end

  local width = shared_label_width()
  if not width then
    -- a device not seen before
    set_label_widths("dynamic")
    if popup_open then
      measure_labels()
      width = shared_label_width()
    end
  end
  if width then
    set_label_widths(width)
  end
end

-- SwitchAudioSource prints one JSON object per line. They are matched by
-- pattern instead of decoded: the tool does not escape the name, so a quote
-- in a device name would be invalid JSON.
local DEVICE_PATTERN = '^{"name": "(.*)", "type": "(%a+)", "id": "(%d+)", "uid": ".*"}$'

-- The leading `echo` keeps SbarLua from parsing the output as JSON, which
-- would hand over only the first object (QUIRKS.md).
local LIST_COMMAND = table.concat({
  "echo devices",
  SWITCH_AUDIO_SOURCE .. " -a -f json",
  "echo current",
  SWITCH_AUDIO_SOURCE .. " -c -t output -f json",
  SWITCH_AUDIO_SOURCE .. " -c -t input -f json",
}, "; ")

-- Read devices and current defaults; events arriving mid-read cause one re-read
local refreshing, pending = false, false
local function refresh()
  if refreshing then
    pending = true
    return
  end
  refreshing = true
  sbar.exec(LIST_COMMAND, function(result)
    local found = { output = {}, input = {} }
    local current = {}
    local section = nil
    for line in tostring(result):gmatch("[^\n]+") do
      if line == "devices" or line == "current" then
        section = line
      else
        local name, kind, id = line:match(DEVICE_PATTERN)
        if name and found[kind] then
          if section == "current" then
            current[kind] = id
          elseif section == "devices" and #found[kind] < MAX_DEVICES then
            table.insert(found[kind], { id = id, name = name })
          end
        end
      end
    end
    devices = found
    current_id = current
    render_popup()
    refreshing = false
    if pending then
      pending = false
      refresh()
    end
  end)
end

local function select_device(kind, index)
  local device = devices[kind][index]
  if not device or device.id == current_id[kind] then
    return
  end
  -- id is digits only (DEVICE_PATTERN) and kind one of KINDS: shell-safe
  sbar.exec(SWITCH_AUDIO_SOURCE .. " -i " .. device.id .. " -t " .. kind, refresh)
end

local function set_popup(open)
  if open == popup_open then
    return
  end
  popup_open = open
  if not open then
    hovered_row = nil
  end
  volume:set({ popup = { drawing = open } })
  if open then
    refresh()
  end
end

if has_switcher then
  for _, kind in ipairs(KINDS) do
    headers[kind] = sbar.add("item", "volume.popup." .. kind, {
      position = "popup." .. volume.name,
      icon = {
        string = icons.system.audio[kind],
        width = 24,
        padding_left = 8,
        padding_right = 4,
      },
      label = { string = KIND_TITLES[kind], padding_right = 8 },
      padding_left = 4,
      padding_right = 4,
      drawing = false,
    })
    for index = 1, MAX_DEVICES do
      local row = sbar.add("item", "volume.popup." .. kind .. "." .. index, {
        position = "popup." .. volume.name,
        icon = {
          width = ROW_ICON_WIDTH,
          padding_left = 8,
          padding_right = 4,
        },
        label = { padding_right = 8 },
        -- hover highlight; spans the row content, not its paddings
        background = {
          color = colors.transparent,
          corner_radius = 6,
          height = 22,
        },
        padding_left = 4,
        padding_right = 4,
        drawing = false,
      })
      device_rows[kind][index] = row
      row:subscribe("mouse.clicked", function()
        select_device(kind, index)
      end)
      row:subscribe({ "mouse.entered", "mouse.exited" }, function(env)
        if env.SENDER == "mouse.entered" then
          hovered_row = row
        elseif hovered_row == row then
          hovered_row = nil
        end
        row:set({ background = row_style(kind, index).background })
      end)
    end
  end

  -- mouse.exited.global is what keeps the popup open while the pointer moves
  -- from the item into it (QUIRKS.md)
  volume:subscribe({ "mouse.entered", "mouse.exited", "mouse.exited.global" }, function(env)
    set_popup(env.SENDER == "mouse.entered")
  end)
end

-- Subscribe to events
volume:subscribe("volume_change", function(env)
  handle_volume_change(env)
  if popup_open then
    refresh()
  end
end)
volume:subscribe("theme_colors_updated", function()
  volume:set(colors.get_item_colors({ accent = "volume" }))
  if has_switcher then
    render_popup()
  end
end)

-- No initial update needed - volume_change events will trigger updates
