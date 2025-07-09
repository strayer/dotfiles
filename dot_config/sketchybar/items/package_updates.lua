-- items/package_updates.lua - Package update monitor for brew and mise

local icons = require("lib.icons")
local colors = require("lib.colors")
local utils = require("lib.utils")
local settings = require("lib.settings")

-- Add package updates item to right side
local package_updates = sbar.add("item", "package_updates", {
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

local update_in_progress = false

-- Update package updates display
local function update_package_updates()
  if update_in_progress then
    return
  end
  update_in_progress = true

  local results = {}
  local pending = 2

  local function process_results()
    if pending > 0 then
      return
    end

    -- Both commands have finished, release the lock
    update_in_progress = false

    local theme_colors = colors.get_colors()
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

    -- Determine color based on update count
    local update_color = theme_colors.item_primary
    if total_count > 20 then
      update_color = theme_colors.critical
    elseif total_count > 10 then
      update_color = theme_colors.warning
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

    package_updates:set({
      icon = {
        string = icons.system.package_updates,
        color = update_color,
      },
      label = {
        string = label_text,
        color = update_color,
      },
    })
  end

  -- Execute brew and mise commands in parallel
  sbar.exec("brew outdated --json", function(brew_result, brew_exit_code)
    results.brew = { result = brew_result, exit_code = brew_exit_code }
    pending = pending - 1
    process_results()
  end)

  sbar.exec("mise outdated --json 2>/dev/null", function(mise_result, mise_exit_code)
    results.mise = { result = mise_result, exit_code = mise_exit_code }
    pending = pending - 1
    process_results()
  end)
end

-- Subscribe to events
package_updates:subscribe("system_woke", update_package_updates)
package_updates:subscribe("routine", update_package_updates)
package_updates:subscribe("forced", update_package_updates)

-- Initial update
update_package_updates()