-- items/omniwm.lua - OmniWM workspace integration (per-display, per-window icons)

local colors = require("lib.colors")
local icons = require("lib.icons")
local settings = require("lib.settings")

---@class WorkspaceState
---@field number integer
---@field display integer                -- SketchyBar arrangement-id
---@field omniwm_display string          -- OmniWM display id (e.g. "display:1")
---@field header string                  -- header item name
---@field bracket string                 -- per-workspace bracket name
---@field icon_names string[]            -- icon item names, growing pool 1..N
---@field member_list string[]           -- cached bracket member list (header + icons)
---@field bracket_created boolean

---@type table<string, WorkspaceState>
local workspace_state = {}

local items_created_this_cycle = false

-- Map: OmniWM display id ("display:1") → SketchyBar arrangement-id. Rebuilt
-- on display_change. The numeric extraction in display_to_sbar is a fallback
-- for the brief window before the map is built or when a display id appears
-- that didn't match any sbar display by frame.
---@type table<string, integer>
local display_map = {}

local function display_to_sbar(omniwm_display_id)
  if not omniwm_display_id then
    return 1
  end
  local mapped = display_map[omniwm_display_id]
  if mapped then
    return mapped
  end
  return tonumber(string.match(omniwm_display_id, "display:(%d+)")) or 1
end

---Build display_map by matching OmniWM displays to SketchyBar displays via
---frame coordinates. OmniWM does not expose CGDirectDisplayID/UUID, so frame
---is the most stable cross-reference available.
local function build_display_map(callback)
  sbar.exec("omniwmctl query displays", function(omniwm_resp)
    local omniwm_displays
    if type(omniwm_resp) == "table" and omniwm_resp.result and omniwm_resp.result.payload then
      omniwm_displays = omniwm_resp.result.payload.displays
    end

    sbar.exec("sketchybar --query displays", function(sbar_displays)
      local new_map = {}

      if type(omniwm_displays) == "table" and type(sbar_displays) == "table" then
        for _, od in ipairs(omniwm_displays) do
          if od.id and od.frame then
            for _, sd in ipairs(sbar_displays) do
              if sd.frame
                and sd.frame.x == od.frame.x
                and sd.frame.y == od.frame.y
                and sd.frame.w == od.frame.width
                and sd.frame.h == od.frame.height
              then
                new_map[od.id] = sd["arrangement-id"]
                break
              end
            end
          end
        end
      end

      display_map = new_map
      if callback then
        callback()
      end
    end)
  end)
end

local function workspace_key(number, display)
  return tostring(number) .. ":" .. tostring(display)
end

local function is_filtered_window(title)
  if not title then
    return false
  end
  -- Outlook reminder popups (German locale)
  return title == "1 Erinnerung" or title:match("^%d+ Erinnerungen$") ~= nil
end

---@param ws_windows table[] OmniWM workspace.windows array (app-grouped)
---@return {glyph: string, focused: boolean}[] One descriptor per visible window
local function collect_window_descriptors(ws_windows)
  local out = {}
  if type(ws_windows) ~= "table" then
    return out
  end
  for _, group in ipairs(ws_windows) do
    local glyph = icons.get_app_icon(group.appName or "")
    local all = group.allWindows
    if type(all) == "table" and #all > 0 then
      for _, w in ipairs(all) do
        if not is_filtered_window(w.title) then
          table.insert(out, { glyph = glyph, focused = w.isFocused == true })
        end
      end
    else
      table.insert(out, { glyph = glyph, focused = group.isFocused == true })
    end
  end
  return out
end

local function ensure_workspace(number, display, omniwm_display)
  local key = workspace_key(number, display)
  local state = workspace_state[key]
  if state then
    state.omniwm_display = omniwm_display
    return state
  end

  local prefix = "left.omniwm." .. tostring(number) .. "." .. tostring(display)
  local header_name = prefix .. ".h"
  local bracket_name = "omniwm.pill." .. tostring(number) .. "." .. tostring(display)

  local header_item = sbar.add("item", header_name, {
    position = "left",
    display = display,
    icon = { padding_left = 6, padding_right = 4 },
    label = { drawing = false },
  })
  header_item:subscribe("mouse.clicked", function()
    sbar.exec("omniwmctl command switch-workspace " .. tostring(number))
  end)

  state = {
    number = number,
    display = display,
    omniwm_display = omniwm_display,
    header = header_name,
    bracket = bracket_name,
    icon_names = {},
    member_list = { header_name },
    bracket_created = false,
  }
  workspace_state[key] = state
  items_created_this_cycle = true
  return state
end

local function ensure_icon(state, idx)
  if state.icon_names[idx] then
    return
  end

  local name = "left.omniwm."
    .. tostring(state.number)
    .. "."
    .. tostring(state.display)
    .. ".w"
    .. tostring(idx)

  local item = sbar.add("item", name, {
    position = "left",
    display = state.display,
    icon = {
      font = { family = settings.font.app_icons, style = "Regular", size = 16.0 },
      padding_left = 2,
      padding_right = 4,
    },
    label = { drawing = false },
  })
  item:subscribe("mouse.clicked", function()
    sbar.exec("omniwmctl command switch-workspace " .. tostring(state.number))
  end)

  state.icon_names[idx] = name
  table.insert(state.member_list, name)
  items_created_this_cycle = true
end

---Permanently delete a workspace's items. Used when OmniWM has dropped the
---workspace from its configuration entirely.
local function remove_workspace(state)
  if state.bracket_created then
    sbar.remove(state.bracket)
    state.bracket_created = false
  end
  for _, name in ipairs(state.icon_names) do
    sbar.remove(name)
  end
  sbar.remove(state.header)
end

---Always remove+recreate the bracket. Used when membership changed or when
---the global left_pill was just recreated (so per-workspace brackets must be
---re-stacked above it).
local function rebuild_bracket(state, theme, ws_focused, visible)
  if state.bracket_created then
    sbar.remove(state.bracket)
    state.bracket_created = false
  end
  if not visible then
    return
  end
  sbar.add("bracket", state.bracket, state.member_list, {
    background = {
      color = ws_focused and theme.highlighted_item_background or theme.item_background,
      corner_radius = 12,
      height = 24,
    },
  })
  state.bracket_created = true
end

---In-place color update. Used for the common case (focus change, no item
---churn) so the pill never blinks off.
local function update_bracket_in_place(state, theme, ws_focused, visible)
  if not visible then
    if state.bracket_created then
      sbar.remove(state.bracket)
      state.bracket_created = false
    end
    return
  end
  if not state.bracket_created then
    rebuild_bracket(state, theme, ws_focused, true)
    return
  end
  sbar.set(state.bracket, {
    background = {
      color = ws_focused and theme.highlighted_item_background or theme.item_background,
    },
  })
end

---Sync one workspace's items (header drawing/colors, icons drawing/colors).
---Returns visibility state for phase-3 bracket processing.
---@return boolean visible, boolean ws_focused
local function update_workspace_items(state, ws, theme)
  local label = ws.displayName or ws.rawName or tostring(state.number)
  local descriptors = collect_window_descriptors(ws.windows)
  local has_windows = #descriptors > 0
  local ws_focused = ws.isFocused == true
  local visible = has_windows or ws_focused

  if not visible then
    sbar.set(state.header, { drawing = false })
    for _, name in ipairs(state.icon_names) do
      sbar.set(name, { drawing = false })
    end
    return false, ws_focused
  end

  sbar.set(state.header, {
    drawing = true,
    icon = {
      string = label,
      color = ws_focused and theme.highlighted_item_primary or theme.item_primary,
    },
  })

  for i, desc in ipairs(descriptors) do
    ensure_icon(state, i)
    sbar.set(state.icon_names[i], {
      drawing = true,
      icon = {
        string = desc.glyph,
        color = desc.focused and theme.highlighted_item_primary or theme.item_primary,
      },
    })
  end
  for i = #descriptors + 1, #state.icon_names do
    sbar.set(state.icon_names[i], { drawing = false })
  end

  return true, ws_focused
end

local function refresh()
  sbar.exec("omniwmctl query workspace-bar", function(response)
    if type(response) ~= "table" then
      print("[omniwm] unexpected query response: " .. tostring(response))
      return
    end
    if response.ok == false then
      print("[omniwm] query failed: " .. tostring(response.kind))
      return
    end
    local payload = response.result and response.result.payload
    local monitors = payload and payload.monitors
    if type(monitors) ~= "table" then
      return
    end

    local theme = colors.get_colors()
    local seen = {}
    local connected_displays = {}

    ---@type {state: WorkspaceState, visible: boolean, ws_focused: boolean}[]
    local bracket_jobs = {}

    -- Phase 1: ensure items exist, set their drawing state and properties.
    for _, monitor in ipairs(monitors) do
      connected_displays[monitor.id] = true
      local display = display_to_sbar(monitor.id)
      for _, ws in ipairs(monitor.workspaces or {}) do
        local number = ws.number
        if number then
          local key = workspace_key(number, display)
          seen[key] = true
          local state = ensure_workspace(number, display, monitor.id)
          local visible, ws_focused = update_workspace_items(state, ws, theme)
          table.insert(bracket_jobs, { state = state, visible = visible, ws_focused = ws_focused })
        end
      end
    end

    -- Phase 1b: handle stale workspaces. If the workspace's display is still
    -- connected, OmniWM dropped the workspace from config — fully remove the
    -- items. If the display is gone, keep state hidden so it reappears on
    -- reconnect.
    for key, state in pairs(workspace_state) do
      if not seen[key] then
        if connected_displays[state.omniwm_display] then
          remove_workspace(state)
          workspace_state[key] = nil
        else
          sbar.set(state.header, { drawing = false })
          for _, name in ipairs(state.icon_names) do
            sbar.set(name, { drawing = false })
          end
          table.insert(bracket_jobs, { state = state, visible = false, ws_focused = false })
        end
      end
    end

    -- Phase 2: refresh global left bracket if new items were created this
    -- cycle (regex needs re-evaluation to pick them up).
    local global_was_rebuilt = items_created_this_cycle
    if items_created_this_cycle then
      items_created_this_cycle = false
      local brackets = require("items.brackets")
      brackets.refresh_left_bracket()
    end

    -- Phase 3: per-workspace brackets must end up drawn ON TOP of the global
    -- left_pill backdrop. SketchyBar draws brackets in creation order, so we
    -- only fully recreate when the global bracket was just recreated this
    -- cycle. In the common case (focus change, no item churn) we update the
    -- background color in place — no flicker.
    for _, job in ipairs(bracket_jobs) do
      if global_was_rebuilt then
        rebuild_bracket(job.state, theme, job.ws_focused, job.visible)
      else
        update_bracket_in_place(job.state, theme, job.ws_focused, job.visible)
      end
    end
  end)
end

sbar.add("event", "omniwm_event")

local handler = sbar.add("item", "left.omniwm_event_handler", { drawing = false, updates = "on" })

handler:subscribe({ "omniwm_event", "system_woke", "forced", "theme_colors_updated" }, refresh)
handler:subscribe("display_change", function()
  build_display_map(refresh)
end)

-- Spawn the long-running event bridge. Track its PID so we only kill our own
-- watcher (and only if the recorded PID still belongs to an `omniwmctl watch`
-- process) instead of stomping on user-started watchers.
local watch_pidfile = "/tmp/sketchybar-omniwm-watch.pid"
sbar.exec(
  "[ -f " .. watch_pidfile .. " ] && { "
    .. "PID=$(cat " .. watch_pidfile .. "); "
    .. "ps -p \"$PID\" -o command= 2>/dev/null | grep -q 'omniwmctl watch' "
    .. "&& kill \"$PID\" 2>/dev/null; "
    .. "}; "
    .. "(omniwmctl watch workspace-bar --exec sketchybar --trigger omniwm_event "
    .. ">/dev/null 2>&1 & echo $! > "
    .. watch_pidfile
    .. ")"
)

build_display_map(refresh)
