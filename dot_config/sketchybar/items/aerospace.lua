-- items/aerospace.lua - Aerospace workspace integration with app icons

local icons = require("lib.icons")
local colors = require("lib.colors")
local settings = require("lib.settings")

-- Register the custom events that will be triggered by external scripts
sbar.add("event", "aerospace_workspace_change", "aerospace_workspace_change_event")
sbar.add("event", "aerospace_refresh", "aerospace_refresh_event")

-- Module state
---@type table<string, {item_name: string, monitor: string}>
local workspace_items = {} -- workspace_name -> {item_name, monitor}

local function create_workspace_item(workspace_name, monitor_id)
  local item_name = "left.space." .. workspace_name

  local workspace_item = sbar.add("item", item_name, {
    position = "left",
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
    sbar.aerospace:workspace(workspace_name)
  end)

  workspace_items[workspace_name] = { item_name = item_name, monitor = monitor_id }
  return workspace_item
end

---@param workspaces_data table[] Aerospace workspace data with workspace,
---                               monitor-appkit-nsscreen-screens-id, workspace-is-focused fields
---@return string|nil focused_workspace_name The name of the currently focused workspace
local function sync_workspace_items(workspaces_data)
  local current_workspaces = {}
  local focused_workspace_name = nil

  if not workspaces_data or type(workspaces_data) ~= "table" then
    print("Error: Invalid workspace data received")
    return nil
  end

  for _, workspace in ipairs(workspaces_data) do
    local workspace_name = workspace.workspace
    local monitor_id = tostring(workspace["monitor-appkit-nsscreen-screens-id"])
    local is_focused = workspace["workspace-is-focused"]

    if workspace_name and workspace_name ~= "" then
      current_workspaces[workspace_name] = { monitor = monitor_id }
      if is_focused then
        focused_workspace_name = workspace_name
      end

      if not workspace_items[workspace_name] then
        create_workspace_item(workspace_name, monitor_id)
      end
      if workspace_items[workspace_name] and workspace_items[workspace_name].monitor ~= monitor_id then
        workspace_items[workspace_name].monitor = monitor_id
      end
    end
  end

  -- Remove workspace items that no longer exist
  for workspace_name in pairs(workspace_items) do
    if not current_workspaces[workspace_name] then
      local workspace_data = workspace_items[workspace_name]
      if workspace_data and workspace_data.item_name then
        sbar.remove(workspace_data.item_name)
      end
      workspace_items[workspace_name] = nil
    end
  end

  return focused_workspace_name
end

---@param focused_workspace_name string|nil The currently focused workspace name
---@param windows_by_workspace table<string, {icons: string[]}> Windows grouped by workspace with app icons
local function update_workspace_styling(focused_workspace_name, windows_by_workspace)
  local theme_colors = colors.get_colors()

  for workspace_name, workspace_data in pairs(workspace_items) do
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
          display = workspace_data.monitor,
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

local function update_all_workspaces()
  sbar.aerospace:query_workspaces(function(workspaces_data)
    if not workspaces_data then
      print("Error: Failed to get aerospace workspaces data for update.")
      return
    end

    local focused_workspace_name = sync_workspace_items(workspaces_data)

    sbar.aerospace:list_all_windows(function(windows_data)
      if not windows_data then
        print("Error: Failed to get aerospace windows data for update.")
        return
      end

      local windows_by_workspace = {}
      if type(windows_data) == "table" then
        for _, window in ipairs(windows_data) do
          local workspace = window.workspace
          if workspace then
            if not windows_by_workspace[workspace] then
              windows_by_workspace[workspace] = { icons = {} }
            end
            table.insert(windows_by_workspace[workspace].icons, icons.get_app_icon(window["app-name"]))
          end
        end
      end

      update_workspace_styling(focused_workspace_name, windows_by_workspace)
    end)
  end)
end

sbar.aerospace:query_workspaces(function(workspaces_data)
  if not workspaces_data then
    print("Error: Failed to get aerospace workspaces list for initialization.")
    return
  end

  sync_workspace_items(workspaces_data)

  -- Always create event handler regardless of initial workspace state to fix startup race conditions
  local event_handler = sbar.add("item", "left.aerospace_event_handler", { drawing = false, updates = "on" })
  event_handler:subscribe({
    "aerospace_workspace_change",
    "aerospace_refresh",
    "front_app_switched",
    "display_change",
    "system_woke",
    "forced",
    "theme_colors_updated",
  }, update_all_workspaces)

  update_all_workspaces()
end)
