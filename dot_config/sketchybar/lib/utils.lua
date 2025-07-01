-- lib/utils.lua - General utility functions

local M = {}

-- Generate Unicode progress bar
function M.generate_unicode_bar(percentage, length)
  length = length or 10
  local filled_length = math.floor((percentage / 100) * length)
  local empty_length = length - filled_length

  local filled_char = "█"
  local empty_char = "░"

  local bar = string.rep(filled_char, filled_length) .. string.rep(empty_char, empty_length)
  return bar
end

-- Split string by delimiter
function M.split(str, delimiter)
  local result = {}
  for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
    table.insert(result, match)
  end
  return result
end

-- Trim whitespace from string
function M.trim(str)
  return str:match("^%s*(.-)%s*$")
end

-- Format time in DD.MM. HH:MM format
function M.format_time()
  local date = os.date("%d.%m.")
  local time = os.date("%H:%M")
  return date, time
end

return M
