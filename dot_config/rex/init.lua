-- Ghostty
rex.bind("ctrl+h", "pane.focus", { direction = "left" })
rex.bind("ctrl+j", "pane.focus", { direction = "down" })
rex.bind("ctrl+k", "pane.focus", { direction = "up" })
rex.bind("ctrl+l", "pane.focus", { direction = "right" })

-- Herdr default TUI bindings (prefix ctrl+b)
rex.bind("ctrl+b>ctrl+b", "pane.send_key", { key = "ctrl+b" })

rex.bind("ctrl+b>s", "client.settings")
rex.bind("ctrl+b>shift+r", "client.config.reload")
rex.bind("ctrl+b>b", "client.sidebar.toggle")

-- Herdr workspaces are Rex sessions
rex.bind("ctrl+b>w", "session.switch")
rex.bind("ctrl+b>shift+n", "session.new")
rex.bind("ctrl+b>shift+w", "session.rename")
rex.bind("ctrl+b>shift+d", "session.close")

rex.bind("ctrl+b>c", "client.tab.new")
rex.bind("ctrl+b>shift+t", "client.tab.rename")
rex.bind("ctrl+b>p", "client.tab.previous")
rex.bind("ctrl+b>n", "client.tab.next")
rex.bind("ctrl+b>shift+x", "client.tab.close")
for i = 1, 9 do
  rex.bind("ctrl+b>" .. i, "client.tab.goto", { index = i })
end

rex.bind("ctrl+b>h", "pane.focus", { direction = "left" })
rex.bind("ctrl+b>j", "pane.focus", { direction = "down" })
rex.bind("ctrl+b>k", "pane.focus", { direction = "up" })
rex.bind("ctrl+b>l", "pane.focus", { direction = "right" })
rex.bind("ctrl+b>tab", "pane.focus_next")
rex.bind("ctrl+b>shift+tab", "pane.focus_previous")
rex.bind("ctrl+b>v", "pane.split", { direction = "right" })
rex.bind("ctrl+b>-", "pane.split", { direction = "down" })
rex.bind("ctrl+b>x", "pane.close")
rex.bind("ctrl+b>z", "pane.zoom")

-- Herdr resize mode
rex.mode("resize", { exclusive = true })
rex.bind("ctrl+b>r", "client.mode.enter", { name = "resize" })
rex.bind("resize/h", "pane.resize", { direction = "left" })
rex.bind("resize/j", "pane.resize", { direction = "down" })
rex.bind("resize/k", "pane.resize", { direction = "up" })
rex.bind("resize/l", "pane.resize", { direction = "right" })
rex.bind("resize/left", "pane.resize", { direction = "left" })
rex.bind("resize/down", "pane.resize", { direction = "down" })
rex.bind("resize/up", "pane.resize", { direction = "up" })
rex.bind("resize/right", "pane.resize", { direction = "right" })
rex.bind("resize/enter", "client.mode.exit")
rex.bind("resize/esc", "client.mode.exit")
rex.bind("resize/ctrl+b>r", "client.mode.exit")

-- German umlauts on the US layout: Rex doesn't compose the macOS opt+u dead
-- key, so type the composed character into the focused terminal directly.
local function type_text(text)
  return function()
    rex.block.call("com.superlogical.terminal", "write", { data = text })
    return true
  end
end

for key, text in pairs({
  ["option+u>a"] = "ä",
  ["option+u>o"] = "ö",
  ["option+u>u"] = "ü",
  ["option+u>shift+a"] = "Ä",
  ["option+u>shift+o"] = "Ö",
  ["option+u>shift+u"] = "Ü",
  ["option+s"] = "ß",
}) do
  rex.bind(key, type_text(text))
end

-- Popups: a floating terminal over the current tab, started in the focused
-- pane's working directory. It closes when its program exits.
local function focused_dir()
  local p = rex.block.call("com.superlogical.terminal", "process", {})
  return p and p.foreground and p.foreground.cwd or os.getenv("HOME")
end

local function popup_action(name, title, command)
  rex.action({
    name = name,
    title = title,
    run = function()
      local _, err = rex.session.new_layer({
        bounds = { 0.1, 0.1, 0.8, 0.8 },
        layout = rex.layout.block({
          flavor = "com.superlogical.terminal.shell",
          options = { command = command, cwd = focused_dir() },
        }),
        focus = true,
      })
      if err ~= nil then
        error(err, 0)
      end
    end,
  })
end

popup_action("popup_nvim", "Open Neovim in Popup", { "nvim" })
popup_action("popup_lazygit", "Open lazygit in Popup", { "lazygit" })

-- Project picker (Open Project…), see projects.lua.
require("projects")
