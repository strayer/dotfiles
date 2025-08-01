-- items/aerospace.lua - Aerospace workspace integration with app icons

local icons = require("lib.icons")
local colors = require("lib.colors")
local utils = require("lib.utils")
local settings = require("lib.settings")

-- Register the custom events that will be triggered by external scripts
sbar.add("event", "aerospace_workspace_change", "aerospace_workspace_change_event")
sbar.add("event", "aerospace_refresh", "aerospace_refresh_event")

-- Module state
local workspace_items = {} -- Stores {item = sbar_item, monitor = monitor_id}

-- Creates a new workspace item in SketchyBar
-- Handles shell escaping for workspace names with special characters
local function create_workspace_item(workspace_name, monitor_id)
  local item_name = "space." .. workspace_name
  -- Escape single quotes for bash: ' becomes '"'"'
  local escaped_workspace_name = string.gsub(workspace_name, "'", "'\"'\"'")

  local workspace_item = sbar.add("item", item_name, {
    position = "left",
    icon = { string = workspace_name },
    label = {
      font = { family = settings.font.app_icons, style = "Regular", size = 16.0 },
      drawing = true,
    },
    click_script = "aerospace workspace '" .. escaped_workspace_name .. "'",
  })

  workspace_items[workspace_name] = { item = workspace_item, monitor = monitor_id }
  return workspace_item
end

-- Synchronizes workspace items with current aerospace state
local function sync_workspace_items(workspaces_result)
  local current_workspaces = {}
  local focused_workspace_name = nil

  local lines = utils.split(utils.trim(workspaces_result), "\n")
  for _, line in ipairs(lines) do
    if line and line ~= "" then
      local parts = utils.split(line, ",")
      local workspace_name = utils.trim(parts[1])
      -- Parse monitor ID as number, fallback to "1" if invalid/missing
      local monitor_id = (parts[2] and utils.trim(parts[2]):match("^%d+$")) or "1"
      local is_focused = parts[3] and utils.trim(parts[3]) == "true"

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
  end

  -- Remove workspace items that no longer exist
  for workspace_name in pairs(workspace_items) do
    if not current_workspaces[workspace_name] then
      workspace_items[workspace_name].item:remove()
      workspace_items[workspace_name] = nil
    end
  end

  return focused_workspace_name
end

-- Updates workspace styling based on focus state and app icons
local function update_workspace_styling(focused_workspace_name, windows_by_workspace)
  local theme_colors = colors.get_colors()

  for workspace_name, workspace_data in pairs(workspace_items) do
    local has_windows = windows_by_workspace[workspace_name] and #windows_by_workspace[workspace_name].icons > 0
    local is_focused = (workspace_name == focused_workspace_name)

    if not is_focused and not has_windows then
      workspace_data.item:set({ drawing = false })
    else
      local item_config = {
        drawing = true,
        display = workspace_data.monitor,
      }
      local app_icons_str = (has_windows and table.concat(windows_by_workspace[workspace_name].icons, " ")) or ""

      if is_focused then
        item_config.background = { color = theme_colors.highlighted_item_background }
        item_config.icon = { color = theme_colors.highlighted_item_primary }
        item_config.label = { string = app_icons_str, color = theme_colors.highlighted_item_primary }
      else
        item_config.background = { color = theme_colors.item_background }
        item_config.icon = { color = theme_colors.item_primary }
        item_config.label = { string = app_icons_str, color = theme_colors.item_primary }
      end

      workspace_data.item:set(item_config)
    end
  end
end

local function update_all_workspaces()
  sbar.exec(
    'aerospace list-workspaces --all --format "%{workspace},%{monitor-appkit-nsscreen-screens-id},%{workspace-is-focused}"',
    function(workspaces_result)
      if not workspaces_result then
        print("Error: Failed to get aerospace workspaces data for update.")
        return
      end

      local focused_workspace_name = sync_workspace_items(workspaces_result)

      sbar.exec(
        "aerospace list-windows --all --json --format '%{app-name}%{workspace}%{monitor-appkit-nsscreen-screens-id}'",
        function(windows_json)
          if not windows_json then
            print("Error: Failed to get aerospace windows data for update.")
            return
          end

          local windows_by_workspace = {}
          if type(windows_json) == "table" then
            for _, window in ipairs(windows_json) do
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
        end
      )
    end
  )
end

sbar.exec(
  'aerospace list-workspaces --all --format "%{workspace},%{monitor-appkit-nsscreen-screens-id},%{workspace-is-focused}"',
  function(workspaces_result)
    if not workspaces_result or workspaces_result == "" then
      print("Error: Failed to get aerospace workspaces list for initialization.")
      return
    end

    sync_workspace_items(workspaces_result)

    -- Always create event handler regardless of initial workspace state to fix startup race conditions
    local event_handler = sbar.add("item", "aerospace_event_handler", { drawing = false, updates = "on" })
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
  end
)
