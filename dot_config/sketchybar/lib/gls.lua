-- gls.lua - Pure helpers for the GLS parcel block of the Steam Frame status
--
-- No sbar calls in here: everything is plain Lua so the parsing and
-- formatting can be exercised from the command line (see the verification
-- notes in items/steam_frame.lua).

local M = {}

-- Short, lowercase status labels for the bar and popup
M.STATUS_SHORT = {
  PREADVICE = "label created",
  INTRANSIT = "in transit",
  INWAREHOUSE = "at parcel center",
  INDELIVERY = "out for delivery",
  DELIVERED = "delivered",
  NORECORD = "no record",
}

local MONTHS = {
  jan = 1,
  feb = 2,
  mar = 3,
  apr = 4,
  may = 5,
  jun = 6,
  jul = 7,
  aug = 8,
  sep = 9,
  oct = 10,
  nov = 11,
  dec = 12,
}

local DOT_FILLED = "●" -- U+25CF
local DOT_HOLLOW = "○" -- U+25CB
local STAGE_COUNT = 5

--- Short status text for a GLS status code
---@param status string|nil
---@return string
function M.status_short(status)
  if type(status) ~= "string" then
    return "unknown"
  end
  return M.STATUS_SHORT[status] or status:lower()
end

--- "2026-09-23T08:03:10" -> "23.09. 08:03"
---@param iso string|nil
---@return string|nil
function M.format_timestamp(iso)
  if type(iso) ~= "string" then
    return nil
  end
  local month, day, hour, minute = iso:match("^%d%d%d%d%-(%d%d)%-(%d%d)T(%d%d):(%d%d)")
  if not month then
    return iso
  end
  return day .. "." .. month .. ". " .. hour .. ":" .. minute
end

--- Parse an ISO-8601 timestamp into an epoch. Naive timestamps are taken as
--- local time (the monitor's `at` fields); a trailing "Z" or "+HH:MM" offset
--- is honoured (the `stored_at` fields are UTC).
---@param iso string|nil
---@return integer|nil
function M.parse_iso(iso)
  if type(iso) ~= "string" then
    return nil
  end
  local y, mo, d, h, mi, sec, rest = iso:match("^(%d%d%d%d)%-(%d%d)%-(%d%d)T(%d%d):(%d%d):?(%d?%d?)(.*)$")
  if not y then
    return nil
  end
  local t = os.time({
    year = tonumber(y),
    month = tonumber(mo),
    day = tonumber(d),
    hour = tonumber(h),
    min = tonumber(mi),
    sec = tonumber(sec) or 0,
  })
  if not t then
    return nil
  end
  rest = rest:gsub("^%.%d+", "") -- drop fractional seconds
  local offset
  if rest == "Z" then
    offset = 0
  else
    local sign, oh, om = rest:match("^([%+%-])(%d%d):?(%d%d)$")
    if not sign then
      return t -- naive: already local
    end
    offset = (tonumber(oh) * 3600 + tonumber(om) * 60) * (sign == "-" and -1 or 1)
  end
  -- os.time() read the fields as local time; shift by the local UTC offset
  -- (isdst copied from the local calendar so mktime does not add an hour)
  local utc_fields = os.date("!*t", t)
  utc_fields.isdst = os.date("*t", t).isdst
  local local_offset = t - os.time(utc_fields)
  return t + local_offset - offset
end

--- Five-stage progress dots: filled for COMPLETE/CURRENT, hollow for PENDING
---@param parcel table
---@return string
function M.stage_dots(parcel)
  local stages = type(parcel) == "table" and parcel.stages or nil
  if type(stages) ~= "table" or #stages == 0 then
    return string.rep(DOT_HOLLOW, STAGE_COUNT)
  end
  local dots = {}
  for i, stage in ipairs(stages) do
    local state = type(stage) == "table" and stage.state or nil
    dots[i] = (state == "COMPLETE" or state == "CURRENT") and DOT_FILLED or DOT_HOLLOW
  end
  return table.concat(dots)
end

--- Parse GLS's free-text delivery window "30-Sep-2026, 09:45 - 11:30".
--- Returns { epoch_day (local midnight), from = "09:45", to = "11:30" } or
--- nil when the text does not match, so callers can fall back to the raw text.
---@param text string|nil
---@return table|nil
function M.parse_expected_delivery(text)
  if type(text) ~= "string" then
    return nil
  end
  local day, mon, year, from, to = text:match("^%s*(%d%d?)%-(%a%a%a)%-(%d%d%d%d),%s*(%d%d?:%d%d)%s*%-%s*(%d%d?:%d%d)")
  if not day then
    return nil
  end
  local month = MONTHS[mon:lower()]
  if not month then
    return nil
  end
  local epoch_day = os.time({ year = tonumber(year), month = month, day = tonumber(day), hour = 0 })
  if not epoch_day then
    return nil
  end
  return { epoch_day = epoch_day, from = from, to = to }
end

--- Local midnight of the day containing `epoch`
local function midnight(epoch)
  local fields = os.date("*t", epoch)
  return os.time({ year = fields.year, month = fields.month, day = fields.day, hour = 0 })
end

--- "today" / "tomorrow" / weekday ("Wed") within a week / "30.09." beyond
---@param epoch_day integer local midnight of the target day
---@param now integer|nil defaults to os.time()
---@return string
function M.relative_day(epoch_day, now)
  now = now or os.time()
  -- day difference via calendar days, so DST shifts do not produce 23h/25h days
  local days = math.floor((midnight(epoch_day) - midnight(now)) / 86400 + 0.5)
  if days == 0 then
    return "today"
  elseif days == 1 then
    return "tomorrow"
  elseif days == -1 then
    return "yesterday"
  elseif days > 1 and days <= 6 then
    return os.date("%a", epoch_day)
  end
  return os.date("%d.%m.", epoch_day)
end

--- The parcel the bar label follows: the first (payload order, Frame first)
--- that is not delivered yet, or the last parcel once all are delivered.
---@param parcels table[]
---@return table|nil parcel, integer|nil index
function M.lead_parcel(parcels)
  if type(parcels) ~= "table" or #parcels == 0 then
    return nil, nil
  end
  for i, parcel in ipairs(parcels) do
    if type(parcel) == "table" and parcel.status ~= "DELIVERED" then
      return parcel, i
    end
  end
  return parcels[#parcels], #parcels
end

--- True when every parcel reports DELIVERED
---@param parcels table[]
---@return boolean
function M.all_delivered(parcels)
  if type(parcels) ~= "table" or #parcels == 0 then
    return false
  end
  for _, parcel in ipairs(parcels) do
    if type(parcel) ~= "table" or parcel.status ~= "DELIVERED" then
      return false
    end
  end
  return true
end

--- Epoch of a parcel's newest event (events are newest first), or nil
---@param parcel table
---@return integer|nil
function M.latest_event_epoch(parcel)
  local event = type(parcel) == "table" and type(parcel.events) == "table" and parcel.events[1] or nil
  if type(event) ~= "table" or type(event.date) ~= "string" or type(event.time) ~= "string" then
    return nil
  end
  return M.parse_iso(event.date .. "T" .. event.time)
end

--- "ok" | "stale" | "error": error when the last GLS fetch failed, stale when
--- the last GLS tick is older than max_age. A compact copy from the Steam
--- payload (`from_steam_payload`) has no tick of its own and counts as ok.
---@param gls table
---@param max_age integer seconds
---@param now integer|nil defaults to os.time()
---@return string
function M.health(gls, max_age, now)
  if type(gls) ~= "table" then
    return "ok"
  end
  if gls.has_error then
    return "error"
  end
  local at = M.parse_iso(gls.at)
  if not at then
    return gls.from_steam_payload and "ok" or "stale"
  end
  if (now or os.time()) - at > max_age then
    return "stale"
  end
  return "ok"
end

--- Truncate to max characters (UTF-8 aware), appending an ellipsis
---@param text string
---@param max integer
---@return string
function M.truncate(text, max)
  text = tostring(text or "")
  if utf8.len(text) == nil or utf8.len(text) <= max then
    return text
  end
  return text:sub(1, utf8.offset(text, max + 1) - 1) .. "…"
end

return M
