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

-- Project picker: an fzf popup over ~/dev. Goes to the session labelled like
-- the chosen directory, or creates that session in the directory first.
-- The app takes no keys while an action runs, so the action only opens the
-- popup. The popup then runs the action again with the chosen name, which
-- needs Remote Control turned on in the app's settings.
local projects_dir = os.getenv("HOME") .. "/dev"

local function run_ok(argv)
  local r, err = rex.exec(argv)
  if r == nil then
    error(err, 0)
  end
  if not r.ok then
    error(r.stderr, 0)
  end
  return r.stdout
end

local function sessions_by_label()
  local listed, err = rex.call("session.list")
  if err ~= nil then
    error(err, 0)
  end
  local sessions = {}
  for _, s in ipairs(listed.sessions) do
    sessions[s.label] = s.session_id
  end
  return sessions
end

-- Runs in the popup: $1 is the list file, $2 the client that asked.
local picker = [[
trap 'rm -f "$1"' EXIT
trap 'exit 0' HUP TERM
sel=$(fzf --ansi --reverse --delimiter '\t' --with-nth 1 \
  --prompt 'Project> ' --header '● session open' < "$1")
[ -n "$sel" ] || exit 0
name=$(printf '%s' "$sel" | cut -f2)
if ! out=$(rex ${2:+-C "$2"} do project_open name="$name" 2>&1); then
  printf '%s\n\nPress Enter to close.' "$out"
  read -r _
fi
exit 0
]]

rex.action({
  name = "project_open",
  title = "Open Project…",
  description = "Pick a directory in ~/dev and go to its session, creating it if needed.",
  keywords = "dev session switch fzf",
  args = { name = "string?" },
  run = function(ctx, args)
    local shell = "com.superlogical.terminal.shell"
    local sessions = sessions_by_label()

    if args.name ~= nil then
      local name = args.name
      if name == "" or name:find("/", 1, true) then
        error("not a project name: " .. name, 0)
      end
      local session_id = sessions[name]
      if session_id == nil then
        local created, err = rex.call("session.create", {
          label = name,
          initial_windows = {
            {
              layout = rex.layout.block({
                flavor = shell,
                options = { cwd = projects_dir .. "/" .. name },
              }),
            },
          },
        })
        if err ~= nil then
          error(err, 0)
        end
        session_id = created.session_id
      end
      rex.client.queue("session.select", { session_id = session_id })
      return
    end

    local names = {}
    local found = run_ok({
      "/usr/bin/find",
      projects_dir,
      "-mindepth",
      "1",
      "-maxdepth",
      "1",
      "-type",
      "d",
      "-not",
      "-name",
      ".*",
    })
    for path in found:gmatch("[^\n]+") do
      names[#names + 1] = path:match("[^/]+$")
    end
    table.sort(names, function(a, b)
      local open_a, open_b = sessions[a] ~= nil, sessions[b] ~= nil
      if open_a ~= open_b then
        return open_a
      end
      return a:lower() < b:lower()
    end)

    local list = run_ok({ "/usr/bin/mktemp" }):gsub("%s+$", "")
    local f = assert(io.open(list, "w"))
    for _, name in ipairs(names) do
      f:write(sessions[name] and "\27[32m●\27[0m " or "  ", name, "\t", name, "\n")
    end
    f:close()

    local _, err = rex.session.new_layer({
      bounds = { 0.25, 0.2, 0.5, 0.6 },
      layout = rex.layout.block({
        flavor = shell,
        options = {
          command = { "/bin/sh", "-c", picker, "sh", list, ctx.client_id or "" },
        },
      }),
      focus = true,
    })
    if err ~= nil then
      os.remove(list)
      error(err, 0)
    end
  end,
})
