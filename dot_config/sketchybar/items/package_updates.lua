-- items/package_updates.lua - Package update monitor for brew and mise

local icons = require("lib.icons")
local colors = require("lib.colors")
local settings = require("lib.settings")

-- Add package updates item to right side
local package_updates = sbar.add("item", "right.package_updates", {
  position = "right",
  icon = {
    string = icons.system.package_updates,
  },
  label = {
    padding_left = 4,
  },
  update_freq = settings.update_freq.package_updates,
  updates = true,
})

-- Process package update results
local function process_package_results(results)
  local mise_count = 0
  local brew_count = 0

  -- Parse brew results
  if results.brew.exit_code == 0 and results.brew.result and type(results.brew.result) == "table" then
    if results.brew.result.formulae then
      brew_count = #results.brew.result.formulae
    end
    if results.brew.result.casks then
      brew_count = brew_count + #results.brew.result.casks
    end
  end

  -- Parse mise results
  if results.mise.exit_code == 0 and results.mise.result and type(results.mise.result) == "table" then
    for _, _ in pairs(results.mise.result) do
      mise_count = mise_count + 1
    end
  end

  local total_count = brew_count + mise_count

  -- Hide item if no updates available
  if total_count == 0 then
    package_updates:set({ drawing = false })
    return
  end

  -- Show item with update counts
  package_updates:set({ drawing = true })

  -- Determine state based on update count
  local state = nil
  if total_count > 20 then
    state = "critical"
  elseif total_count > 10 then
    state = "warning"
  end

  -- Format label with counts
  local label_text = ""
  if brew_count > 0 then
    label_text = "b:" .. brew_count
  end
  if mise_count > 0 then
    if label_text ~= "" then
      label_text = label_text .. " "
    end
    label_text = label_text .. "m:" .. mise_count
  end

  -- Get colors based on state and set properties
  local config = colors.get_item_colors({ state = state })
  config.icon = { string = icons.system.package_updates }
  config.label = { string = label_text }
  package_updates:set(config)
end

-- Update package updates display
local function update_package_updates()
  -- Execute combined command to get both brew and mise results
  sbar.exec("~/.bin/outdated-packages.sh", function(combined_result, exit_code)
    local results = {}
    if exit_code == 0 and combined_result then
      local parsed = combined_result
      if type(parsed) == "table" then
        results.brew = { result = parsed.brew, exit_code = 0 }
        results.mise = { result = parsed.mise, exit_code = 0 }
      else
        -- Fallback if parsing fails
        results.brew = { result = nil, exit_code = 1 }
        results.mise = { result = nil, exit_code = 1 }
      end
    else
      results.brew = { result = nil, exit_code = 1 }
      results.mise = { result = nil, exit_code = 1 }
    end
    process_package_results(results)
  end)
end

-- Handle theme changes
local function handle_theme_change()
  package_updates:set(colors.get_item_colors())
end

-- Subscribe to events
package_updates:subscribe("system_woke", update_package_updates)
package_updates:subscribe("routine", update_package_updates)
package_updates:subscribe("theme_colors_updated", handle_theme_change)

-- Initial update
update_package_updates()
