-- items/rift.lua - Rift workspace integration with app icons (per-display)

local icons = require("lib.icons")
local colors = require("lib.colors")
local settings = require("lib.settings")

-- Module state
-- workspace key includes display to support same workspace name on multiple displays
---@type table<string, {item_name: string, index: number, display: number}>
local workspace_items = {} -- "workspace_name:display" -> {item_name, index, display}

-- Track if new items were created during this update cycle
local items_created_this_cycle = false

-- Cache for display UUID to SketchyBar display number mapping
---@type table<string, number>
local display_map = {}

-- Cache for space_id to SketchyBar display number mapping
---@type table<number, number>
local space_to_display = {}

-- Forward declarations
local update_all_workspaces
local update_display

--- Build mapping from Rift display UUID to SketchyBar display number
---@param callback function|nil Optional callback to run after map is built
local function build_display_map(callback)
  sbar.exec("sketchybar --query displays", function(displays)
    if displays and type(displays) == "table" then
      local new_map = {}
      for _, display in ipairs(displays) do
        if display.UUID then
          new_map[display.UUID] = display["arrangement-id"]
        end
      end
      display_map = new_map
    end
    if callback then
      callback()
    end
  end)
end

--- Get SketchyBar display number for a given UUID, with caching
---@param uuid string Display UUID from Rift
---@param fallback_screen_id number Fallback screen_id from Rift
---@return number SketchyBar display number
local function get_sbar_display(uuid, fallback_screen_id)
  local sbar_display = display_map[uuid]
  if not sbar_display then
    sbar_display = fallback_screen_id
  end
  return sbar_display
end

local function get_workspace_key(workspace_name, display)
  return workspace_name .. ":" .. tostring(display)
end

local function create_workspace_item(workspace_name, workspace_index, display)
  local key = get_workspace_key(workspace_name, display)
  local item_name = "left.space." .. workspace_name .. "." .. tostring(display)

  local workspace_item = sbar.add("item", item_name, {
    position = "left",
    display = display,
    icon = {
      string = workspace_name,
      padding_left = 8,
      padding_right = 2,
    },
    label = {
      font = { family = settings.font.app_icons, style = "Regular", size = 16.0 },
      drawing = true,
      padding_right = 8,
    },
    background = {
      corner_radius = 16,
      height = 24,
    },
  })

  workspace_item:subscribe("mouse.clicked", function(_)
    sbar.exec("rift-cli execute workspace switch " .. tostring(workspace_index))
  end)

  workspace_items[key] = { item_name = item_name, index = workspace_index, display = display }
  return workspace_item
end

---@param workspaces_data table[] Rift workspace data
---@param display number SketchyBar display number
---@return string|nil focused_workspace_name The name of the currently focused workspace
---@return table<string, {icons: string[]}> windows_by_workspace Windows grouped by workspace
local function process_workspace_data(workspaces_data, display)
  local focused_workspace_name = nil
  local windows_by_workspace = {}

  if not workspaces_data or type(workspaces_data) ~= "table" then
    return nil, {}
  end

  for _, workspace in ipairs(workspaces_data) do
    local workspace_name = workspace.name
    local workspace_index = workspace.index
    local is_active = workspace.is_active

    if workspace_name and workspace_name ~= "" then
      if is_active then
        focused_workspace_name = workspace_name
      end

      local key = get_workspace_key(workspace_name, display)

      -- Create workspace item if it doesn't exist
      if not workspace_items[key] then
        create_workspace_item(workspace_name, workspace_index, display)
        items_created_this_cycle = true
      end

      -- Process windows for this workspace
      windows_by_workspace[workspace_name] = { icons = {} }
      if workspace.windows and type(workspace.windows) == "table" then
        for _, window in ipairs(workspace.windows) do
          local title = window.title or ""
          -- Filter out Outlook reminder popups
          local is_filtered = title:match("^%d+ Erinnerungen$") or title == "1 Erinnerung"
          if not is_filtered then
            local app_name = window.app_name or ""
            table.insert(windows_by_workspace[workspace_name].icons, icons.get_app_icon(app_name))
          end
        end
      end
    end
  end

  return focused_workspace_name, windows_by_workspace
end

---@param focused_workspace_name string|nil The currently focused workspace name
---@param windows_by_workspace table<string, {icons: string[]}> Windows grouped by workspace with app icons
---@param display number SketchyBar display number
local function update_workspace_styling(focused_workspace_name, windows_by_workspace, display)
  -- Refresh brackets if new items were created this cycle
  if items_created_this_cycle then
    items_created_this_cycle = false
    local brackets = require("items.brackets")
    brackets.refresh_left_bracket()
  end

  local theme_colors = colors.get_colors()

  for key, workspace_data in pairs(workspace_items) do
    -- Only update items for this display
    if workspace_data.display == display then
      -- Extract workspace name from key
      local workspace_name = key:match("^(.+):")

      local has_windows = windows_by_workspace[workspace_name] and #windows_by_workspace[workspace_name].icons > 0
      local is_focused = (workspace_name == focused_workspace_name)

      if workspace_data.item_name then
        -- Hide workspaces unless focused or containing windows
        if not is_focused and not has_windows then
          sbar.set(workspace_data.item_name, { drawing = false })
        else
          local app_icons_str = (has_windows and table.concat(windows_by_workspace[workspace_name].icons, " ")) or ""
          local item_config = {
            drawing = true,
            display = display,
            icon = {
              padding_left = 8,
              padding_right = 2,
            },
            label = {
              string = app_icons_str,
              padding_right = 8,
            },
          }

          if is_focused then
            -- Focused workspace gets highlighted background
            item_config.background = {
              color = theme_colors.highlighted_item_background,
              corner_radius = 16,
              height = 24,
            }
            item_config.icon.color = theme_colors.highlighted_item_primary
            item_config.label.color = theme_colors.highlighted_item_primary
          else
            -- Unfocused workspaces with windows are transparent
            item_config.background = { color = theme_colors.item_background }
            item_config.icon.color = theme_colors.item_primary
            item_config.label.color = theme_colors.item_primary
          end

          sbar.set(workspace_data.item_name, item_config)
        end
      end
    end
  end
end

--- Update a single display's workspaces
---@param space_id number macOS space ID
---@param display_uuid string|nil Display UUID (optional, for mapping)
update_display = function(space_id, display_uuid)
  -- Get SketchyBar display number
  local sbar_display
  if display_uuid and display_map[display_uuid] then
    sbar_display = display_map[display_uuid]
  elseif space_to_display[space_id] then
    sbar_display = space_to_display[space_id]
  end

  if not sbar_display then
    -- Need to query displays to find the mapping, then update
    sbar.exec("rift-cli query displays", function(displays)
      if not displays or type(displays) ~= "table" then
        return
      end

      for _, display_info in ipairs(displays) do
        if display_info.space == space_id then
          sbar_display = get_sbar_display(display_info.uuid, display_info.screen_id)
          space_to_display[space_id] = sbar_display
          break
        end
      end

      if sbar_display then
        sbar.exec("rift-cli query workspaces --space-id " .. space_id, function(workspaces)
          if workspaces and type(workspaces) == "table" then
            local focused_workspace_name, windows_by_workspace = process_workspace_data(workspaces, sbar_display)
            update_workspace_styling(focused_workspace_name, windows_by_workspace, sbar_display)
          end
        end)
      end
    end)
    return
  end

  -- Query workspaces for this specific display/space
  sbar.exec("rift-cli query workspaces --space-id " .. space_id, function(workspaces)
    if workspaces and type(workspaces) == "table" then
      local focused_workspace_name, windows_by_workspace = process_workspace_data(workspaces, sbar_display)
      update_workspace_styling(focused_workspace_name, windows_by_workspace, sbar_display)
    end
  end)
end

--- Update all displays (used for system events)
update_all_workspaces = function()
  sbar.exec("rift-cli query displays", function(displays)
    if not displays or type(displays) ~= "table" then
      return
    end

    -- Update space_to_display cache
    for _, display_info in ipairs(displays) do
      if display_info.space then
        local sbar_display = get_sbar_display(display_info.uuid, display_info.screen_id)
        space_to_display[display_info.space] = sbar_display
      end
    end

    for _, display_info in ipairs(displays) do
      local space_id = display_info.space
      local sbar_display = space_to_display[space_id]

      if space_id and sbar_display then
        sbar.exec("rift-cli query workspaces --space-id " .. space_id, function(workspaces)
          if workspaces and type(workspaces) == "table" then
            local focused_workspace_name, windows_by_workspace = process_workspace_data(workspaces, sbar_display)
            update_workspace_styling(focused_workspace_name, windows_by_workspace, sbar_display)
          end
        end)
      end
    end
  end)
end

-- Register custom events
sbar.add("event", "rift_workspace_change", "rift_workspace_change_event")
sbar.add("event", "rift_windows_change", "rift_windows_change_event")
sbar.add("event", "rift_refresh", "rift_refresh_event")

-- Create event handler
local event_handler = sbar.add("item", "left.rift_event_handler", { drawing = false, updates = "on" })

-- Targeted update for workspace/window changes
event_handler:subscribe({ "rift_workspace_change", "rift_windows_change" }, function(env)
  local space_id = tonumber(env.RIFT_SPACE_ID)
  local display_uuid = env.RIFT_DISPLAY_UUID
  if space_id then
    update_display(space_id, display_uuid)
  else
    update_all_workspaces()
  end
end)

-- Full refresh for system events
event_handler:subscribe({
  "rift_refresh",
  "system_woke",
  "forced",
  "theme_colors_updated",
}, update_all_workspaces)

-- Rebuild display map on display changes
event_handler:subscribe("display_change", function()
  space_to_display = {}
  build_display_map(update_all_workspaces)
end)

-- Build display map first, then do initial update
build_display_map(update_all_workspaces)
