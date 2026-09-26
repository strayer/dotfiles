-- known_networks.lua - Known WiFi networks and hotspots per device (hashed)
--
-- The network_type item only shows the SSID label when the current network
-- is NOT one of the known ones below. Known networks show the icon only.
--
-- PRIVACY: this repository is public. Only store salted hashes here, never
-- the plain network names. Values are the lowercase hex HMAC-SHA256 of the
-- SSID's UTF-8 bytes, keyed with the `hash_salt` chezmoi secret (deployed to
-- ~/.config/dotfiles/hash-salt). This is the same value the network watcher daemon
-- sends as NETWORK_SSID_HASH. Changing the salt invalidates every entry
-- below; re-generate them all with the helper afterwards.
--
-- Generate hashes with the helper script in ~/.bin/:
--   sketchybar-ssid-hash "<SSID>"      -- hash of a given SSID
--   sketchybar-ssid-hash --current     -- hash of the currently connected network
--   sketchybar-ssid-hash --preferred   -- hashes of all this Mac's preferred networks

local settings = require("lib.settings")

local M = {}

-- Default WiFi networks per device, keyed by hostname (settings.hostname).
-- Connected via wifi to one of these -> icon only, no label.
M.default_wifi = {
  yobuko = {
    "9b0fd5cbfa38daa747330547ba5779f456cd617ca12b341043deb02f602432d2",
  },
  ["CO-MBP-KC9KQV64V3"] = {
    "81cd88f35d8e9190a812abc9fac7ab352876bb3db757acd1aeb68f95e75c02d9",
    "27f45676889d1a7295cbafa9db8050ad965bea18328e639982481448a4ec6157",
  },
}

-- Known hotspot devices per machine, keyed by hostname (settings.hostname).
-- Connected via hotspot to one of these -> icon only, no label.
M.known_hotspots = {
  yobuko = {
    "1d70058f4c639734fcd1e11ae944c1b0ed1d378d9dd3447caef8d3fbe34e4653",
    "f49d0b142961d592a653c6d8ad7b47d9ab6d6da6b764be51bb675e55232acf48",
  },
  ["CO-MBP-KC9KQV64V3"] = {
    "f49d0b142961d592a653c6d8ad7b47d9ab6d6da6b764be51bb675e55232acf48",
  },
}

-- Build lookup sets once at load time
local function to_set(list)
  local set = {}
  for _, hash in ipairs(list or {}) do
    set[hash:lower()] = true
  end
  return set
end

local default_wifi_set = to_set(M.default_wifi[settings.hostname])
local known_hotspot_set = to_set(M.known_hotspots[settings.hostname])

-- Returns true if hash is a default WiFi network for this device
function M.is_default_wifi(hash)
  if hash == nil or hash == "" then
    return false
  end
  return default_wifi_set[hash:lower()] == true
end

-- Returns true if hash is one of this device's known hotspot devices
function M.is_known_hotspot(hash)
  if hash == nil or hash == "" then
    return false
  end
  return known_hotspot_set[hash:lower()] == true
end

return M
