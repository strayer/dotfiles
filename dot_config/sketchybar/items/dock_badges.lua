-- items/dock_badges.lua - One item per Dock app with a notification badge (app icon + badge text)
--
-- Event-driven: `dock-badge-counter watch` (brew service, see ~/.config/dock-badge-counter/config.toml)
-- triggers `dock_badges BADGES=<json>` on start, on every change and once a minute as a heartbeat,
-- so a reloaded bar catches up by itself. Nothing here polls.

local icons = require("lib.icons")
local colors = require("lib.colors")
local settings = require("lib.settings")
local brackets = require("items.brackets")

sbar.add("event", "dock_badges")

-- Hidden anchor: receives the event and pins where the per-app items go (next to the ping item).
local anchor = sbar.add("item", "right.dock_badges", {
  position = "right",
  drawing = false,
  updates = true, -- keep receiving events while hidden (default is "when_shown")
})

local items = {} -- app name -> { name = item name, item = handle }

local function item_name(app)
  return "right.dock_badges." .. app:gsub("[^%w]", "_")
end

local function styled(app, badge)
  local config = colors.get_item_colors()
  config.icon.string = icons.get_app_icon(app)
  config.icon.font = { family = settings.font.app_icons, style = "Regular", size = 16.0 }
  config.label.string = badge
  config.label.padding_left = 2
  return config
end

local function apply(badges)
  local membership_changed = false

  for app, entry in pairs(items) do
    if badges[app] == nil then
      sbar.remove(entry.name)
      items[app] = nil
      membership_changed = true
    end
  end

  local apps = {}
  for app in pairs(badges) do
    table.insert(apps, app)
  end
  table.sort(apps)

  for _, app in ipairs(apps) do
    local entry = items[app]
    if entry then
      entry.item:set(styled(app, badges[app]))
    else
      local name = item_name(app)
      local item = sbar.add("item", name, { position = "right" })
      item:set(styled(app, badges[app]))
      items[app] = { name = name, item = item }
      membership_changed = true
    end
  end

  -- The pill bracket resolves its /right\..*/ members only when created; rebuild it so new
  -- items get the background (and removed ones drop out).
  if membership_changed then
    brackets.refresh_right_bracket()
  end

  -- Pin the order in one call (separate async moves would race). Each move puts the item
  -- directly left of the anchor, pushing the previous ones further left, so iterating
  -- alphabetically yields A…Z left→right ending next to the ping item.
  if #apps > 0 then
    local moves = {}
    for _, app in ipairs(apps) do
      table.insert(moves, "--move " .. items[app].name .. " after right.dock_badges")
    end
    sbar.exec("sketchybar " .. table.concat(moves, " "))
  end
end

local last_badges = {}

anchor:subscribe("dock_badges", function(env)
  local badges = env.BADGES or {}
  if type(badges) == "string" then
    local ok, decoded = pcall(require("cjson").decode, badges)
    badges = ok and decoded or {}
  end
  last_badges = badges
  apply(badges)
end)

anchor:subscribe("theme_colors_updated", function()
  apply(last_badges)
end)
