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

-- Hidden anchor: receives the event and pins where the per-app items go (between the
-- clock and system islands).
local anchor = sbar.add("item", "right.dock_badges", {
  position = "right",
  drawing = false,
  updates = true, -- keep receiving events while hidden (default is "when_shown")
})

local items = {} -- app name -> { name = item name, item = handle }

-- Attention tiers, coloring icon and count: important = warm accent (people
-- are waiting on you), normal = blue, unimportant = regular text color.
-- Only the extremes are listed - unlisted apps default to normal. No muting
-- anywhere: a muted tone stands out against the rest of the bar.
local APP_TIERS = {
  ["Microsoft Teams"] = "important",
  ["Signal"] = "important",
  ["Thunderbird"] = "unimportant",
  ["Thunderbird Beta"] = "unimportant",
  ["Microsoft Outlook"] = "unimportant",
}
local TIER_RANK = { important = 1, normal = 2, unimportant = 3 }

local function tier_of(app)
  return APP_TIERS[app] or "normal"
end

local function item_name(app)
  return "right.dock_badges." .. app:gsub("[^%w]", "_")
end

local function styled(app, badge, is_first, is_last)
  local theme_colors = colors.get_colors()
  local config = colors.get_item_colors()
  -- Chipless: 16pt app glyph + bold count, icon and count colored by tier.
  -- Badges without a count ("•") show icon-only.
  local tier_color = theme_colors.badge_tiers[tier_of(app)] or theme_colors.item_primary
  local is_dot = not badge:match("%w")
  -- Tight paddings between badges (the default item paddings read huge here),
  -- but the island's outermost badges get extra outside padding so the ends
  -- match the other islands' ~12pt corner insets
  config.padding_left = 2
  config.padding_right = 2
  config.icon.string = icons.get_app_icon(app)
  config.icon.font = { family = settings.font.app_icons, style = "Regular", size = 16.0 }
  -- app-icons font is optically centered; don't apply the PragmataPro lift
  config.icon.y_offset = 0
  config.icon.padding_left = is_first and 10 or 6
  local trailing = is_last and 10 or 6
  config.icon.padding_right = is_dot and trailing or 2
  config.label.string = badge
  config.label.drawing = not is_dot
  config.label.color = tier_color
  config.label.font = { family = settings.font.numbers, style = "Bold", size = 14.0 }
  config.label.padding_left = 3
  config.label.padding_right = trailing
  config.icon.color = tier_color
  config.background = { drawing = false }
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
  -- Important tiers first (leftmost in the island), alphabetical within a tier
  table.sort(apps, function(a, b)
    local rank_a, rank_b = TIER_RANK[tier_of(a)], TIER_RANK[tier_of(b)]
    if rank_a ~= rank_b then
      return rank_a < rank_b
    end
    return a < b
  end)

  for i, app in ipairs(apps) do
    local is_first, is_last = i == 1, i == #apps
    local entry = items[app]
    if entry then
      entry.item:set(styled(app, badges[app], is_first, is_last))
    else
      local name = item_name(app)
      local item = sbar.add("item", name, { position = "right" })
      item:set(styled(app, badges[app], is_first, is_last))
      items[app] = { name = name, item = item }
      membership_changed = true
    end
  end

  -- The island bracket resolves its member regex only when created; rebuild it
  -- so new items get the background (and it disappears entirely with the last
  -- badge). The neighboring gap spacer goes with it.
  if membership_changed then
    brackets.refresh_badge_island(#apps > 0)
    sbar.set("right.gap.system_badges", { drawing = #apps > 0 })
  end

  -- Pin the order in one call (separate async moves would race). Each move puts the item
  -- directly left of the anchor, pushing the previous ones further left, so iterating in
  -- sorted order yields tier-then-alphabetical left→right ending next to the anchor.
  if #apps > 0 then
    local moves = {}
    for _, app in ipairs(apps) do
      table.insert(moves, "--move " .. items[app].name .. " after right.dock_badges")
    end
    sbar.exec(settings.sketchybar_bin .. " " .. table.concat(moves, " "))
  end
end

local last_badges = {}

anchor:subscribe("dock_badges", function(env)
  local badges = env.BADGES or {}
  if type(badges) == "string" then
    local ok, decoded = pcall(require("cjson").decode, badges)
    badges = ok and decoded or {}
  end
  -- A scalar/array payload would make apply() throw (and poison last_badges)
  if type(badges) ~= "table" then
    badges = {}
  end
  last_badges = badges
  apply(badges)
end)

anchor:subscribe("theme_colors_updated", function()
  apply(last_badges)
end)
