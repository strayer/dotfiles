-- items/aerospace.lua - Aerospace workspace integration with app icons

local icons = require("lib.icons")
local colors = require("lib.colors")
local utils = require("lib.utils")
local settings = require("lib.settings")

-- Register the custom event that will be triggered by an external script
sbar.add("event", "aerospace_workspace_change", "aerospace_workspace_change_event")

-- Module state
local workspace_items = {} -- Stores {item = sbar_item, monitor = monitor_id}

-- The single source of truth for updating all workspaces
local function update_all_workspaces()
  -- Asynchronously fetch all necessary data

  sbar.exec("aerospace list-workspaces --focused", function(focused_ws_name)
    -- Fetch all windows with the necessary data points in a single call
    sbar.exec(
      "aerospace list-windows --all --json --format '%{app-name}%{workspace}%{monitor-appkit-nsscreen-screens-id}'",
      function(windows_json)
        if not focused_ws_name or not windows_json then
          print("Error: Failed to get aerospace data for update.")
          return
        end

        focused_ws_name = utils.trim(focused_ws_name)
        local theme_colors = colors.get_colors()

        -- Process windows data to group icons by workspace
        local windows_by_workspace = {}
        if type(windows_json) == "table" then
          for _, window in ipairs(windows_json) do
            local ws = window.workspace
            if ws then
              if not windows_by_workspace[ws] then
                windows_by_workspace[ws] = { icons = {} }
              end
              table.insert(windows_by_workspace[ws].icons, icons.get_app_icon(window["app-name"]))
            end
          end
        end

        -- Iterate through all managed workspace items and update them
        for ws_name, ws_data in pairs(workspace_items) do
          local has_windows = windows_by_workspace[ws_name] and #windows_by_workspace[ws_name].icons > 0
          local is_focused = (ws_name == focused_ws_name)

          if not is_focused and not has_windows then
            ws_data.item:set({ drawing = false })
          else
            local item_config = {
              drawing = true,
              display = ws_data.monitor, -- Use the initial monitor ID
            }
            local app_icons_str = (has_windows and table.concat(windows_by_workspace[ws_name].icons, " ")) or ""

            if is_focused then
              item_config.background = { color = theme_colors.highlighted_item_background }
              item_config.icon = { color = theme_colors.highlighted_item_primary }
              item_config.label = { string = app_icons_str, color = theme_colors.highlighted_item_primary }
            else
              item_config.background = { color = theme_colors.item_background }
              item_config.icon = { color = theme_colors.item_primary }
              item_config.label = { string = app_icons_str, color = theme_colors.item_primary }
            end

            ws_data.item:set(item_config)
          end
        end
      end
    )
  end)
end

-- Initialize all workspace items once at the start
sbar.exec(
  'aerospace list-workspaces --all --format "%{workspace},%{monitor-appkit-nsscreen-screens-id}"',
  function(result)
    if not result or result == "" then
      print("Error: Failed to get aerospace workspaces list for initialization.")
      return
    end

    local lines = utils.split(utils.trim(result), "\n")
    for _, line in ipairs(lines) do
      local parts = utils.split(line, ",")
      local ws_name = utils.trim(parts[1])
      local monitor_id = (parts[2] and utils.trim(parts[2]):match("^%d+$")) or "1"

      if ws_name and ws_name ~= "" then
        local item_name = "space." .. ws_name
        local escaped_ws_name = string.gsub(ws_name, "'", "'\"'\"'")

        local workspace_item = sbar.add("item", item_name, {
          position = "left",
          icon = { string = ws_name },
          label = {
            font = { family = settings.font.app_icons, style = "Regular", size = 16.0 },
            drawing = true,
          },
          click_script = "aerospace workspace '" .. escaped_ws_name .. "'",
        })

        workspace_items[ws_name] = { item = workspace_item, monitor = monitor_id }
      end
    end

    -- Create a single, invisible item to handle events centrally
    if #lines > 0 then
      local event_handler = sbar.add("item", "aerospace_event_handler", { drawing = false, updates = "on" })
      event_handler:subscribe({
        "aerospace_workspace_change",
        "space_windows_change",
        "display_change",
        "system_woke",
        "forced",
        "theme_change",
      }, update_all_workspaces)
    end

    -- Perform the initial full update
    update_all_workspaces()
  end
)
