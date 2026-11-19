# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a chezmoi dotfiles repository that manages configuration files across multiple environments (work and home machines). The repository uses Go templating for environment-specific configurations and supports automated theme switching across all applications.

## Chezmoi File Naming Conventions

- `dot_` prefix: Files/directories that become `.filename` in the home directory
- `executable_` prefix: Files that should be executable after deployment
- `symlink_` prefix: Files that should be symlinked rather than copied
- `private_` prefix: Files with restricted permissions
- `.tmpl` suffix: Template files using Go templating with chezmoi variables

### Removing Deployed Files

Deleting a file from the source state does **not** delete it from the home directory: chezmoi simply stops managing it and the old copy stays behind. Chezmoi has three ways to delete targets, so never claim it can't or that only `exact_` does:

- `.chezmoiremove` (repo root): list of target paths relative to `~`, one per line, always rendered as a template. **This repo's default**: when removing a managed file or directory, delete it from the source state *and* add its target path here. Directories listed are removed with their contents.
- `remove_` prefix: a source entry like `dot_bin/remove_foo` deletes `~/.bin/foo` (file or symlink; a directory only if empty).
- `exact_` directory prefix: removes everything in the target directory that the source state doesn't list (used for `~/.bin/raycast-scripts`).

## Common Commands

### Chezmoi Management

```bash
chezmoi apply          # Apply changes to home directory
chezmoi diff           # Show pending changes before applying
chezmoi edit <file>    # Edit files in chezmoi source directory
chezmoi cd             # Navigate to chezmoi source directory (/Users/grunewaldtsv/.local/share/chezmoi)
chezmoi update         # Pull and apply changes from remote repository
```

### Custom Scripts (in ~/.bin/)

```bash
tm <session>                         # tmux session manager (attach or create)
toggle-theme.sh [dark|light]         # Switch the terminal tools' theme; no argument toggles
install-sbarlua.sh                   # Install SbarLua for SketchyBar configuration
dot-services [status|install|restart|uninstall] [NAME…]  # Build, install and restart this repo's daemons and built tools per host (see dot-services below)
rift-pip-auto [toggle]               # Rift event hook: auto-PiP for hidden Teams calls; `toggle` mirrors the focused window (Alt+Ctrl+P); without rift-pip it logs once and stays quiet
sketchybar-ssid-hash [SSID|--current|--preferred]  # Print salted SSID hashes (HMAC-SHA256) for sketchybar/lib/known_networks.lua
rift-debug-log clear|last [MIN]|full|status  # Clear or snapshot rift's debug log (/tmp/rift_$USER.*.log) to ~/tmp/rift-debug-logs as folder + zip; -a redacts PII via `claude -p` (Sonnet)
secretive-ssh-keygen [args]          # SSH key generation using Secretive app
restart-gpg-agent.fish               # GPG agent management for multi-user conflicts
tinycast-sync-commands [-n]          # Sync Tinycast custom commands with ~/.bin/raycast-scripts (macOS only)
```

### Launcher Scripts (in ~/.bin/raycast-scripts/)

```bash
firefox-new-window                   # Open new Firefox Developer Edition window
ghostty-new-window                   # Open new Ghostty terminal window (AppleScript)
reload-sketchybar                    # Reload SketchyBar configuration for development
```

Tinycast imports these scripts as custom commands. `.chezmoiscripts/run_onchange_after_20-tinycast-sync-commands.sh.tmpl` reruns `tinycast-sync-commands` whenever a script changes or Tinycast gets installed: it adds, updates (keeping each command's id, so hotkeys and aliases survive) and removes the commands that point into this folder, leaving other custom commands alone. Tinycast can't show `@raycast.icon`; an optional `# @tinycast.icon <SF Symbol>` directive sets the command's icon instead. The sync quits and relaunches a running Tinycast only when something changed (needs Automation permission for the terminal); the previous list is saved to `~/.cache/tinycast-sync/`. A failed sync fails `chezmoi apply`, so the next apply retries it. The folder is `exact_`: a script deleted from the repo is deleted from `~/.bin/raycast-scripts` too, and the sync then drops its command.

### Homebrew Package Discovery

```bash
brew info <package>                  # Get detailed information about a package (description, dependencies, installation status)
brew search <term>                   # Search for packages by name or description
brew bundle cleanup --file Brewfile  # Show packages installed but missing from this repository's Brewfile
```

## Architecture & Environment Detection

### Hostname-Based Configuration

- **Work machine**: `CO-MBP-KC9KQV64V3` - Different Git signing, package sets, restricted configurations
- **Home machine**: `yobuko` - Full package access, personal configurations
- Templates use `{{ .chezmoi.hostname }}` for conditional logic

### Encrypted Secrets

This repository is public. Sensitive or critical values go into the
age-encrypted secrets file, never into plain source files, code comments
or commit messages. That covers credentials and tokens, and also anything
that points to private infrastructure or people: URLs and hostnames of
private or self-hosted services, internal endpoints, IP addresses,
network names, personal email addresses.

- **Storage**: `.chezmoisecrets.age` holds YAML encrypted with age
  (Secure Enclave identity in `~/.config/chezmoi/age-identity.txt`).
  chezmoi reads it through the `[secret]` command
  `dot_bin/executable_chezmoi-secrets`.
- **Use in templates**: `{{ (secret | fromYaml).<key> }}`, e.g.
  `atuin_sync_server`, `mealplan_url`, `hash_salt`. The file needs the
  `.tmpl` suffix.
- **An existing `secret` lookup is deliberate.** When its value changes,
  update the secret, not the template. Never replace a lookup with a
  literal or drop the `.tmpl` suffix to "simplify" a file, even when the
  new value looks public. A value the user pastes into the chat is not
  permission to put it in the repo. Ask first.
- **Changing a value**: agents don't decrypt the file or print its
  contents. Tell the user which key to set to which value and have them
  run `! chezmoi-secrets edit`. Afterwards, `chezmoi apply` the affected
  target and check that the rendered file has the new value.
- **New values**: if a value might be sensitive, default to a secret and
  say so. If the repo only needs to compare against a private string,
  store an HMAC hash keyed with `hash_salt` instead (see Security &
  Privacy).
- **Before committing**: check `git diff --cached` and the commit
  message for plain-text values. Once a value has been pushed, treat it
  as leaked: rotate or replace it, because reverting the commit doesn't
  remove it.

### Theme Management System

`toggle-theme.sh` switches the terminal tools between a dark and a light theme. It runs only when called by hand; nothing follows the macOS appearance automatically.

- **Themes**: dark is tokyonight storm, light is Catppuccin Latte
- **Applications**: bat, fish, lsd, git-delta, neovim (running instances get `SIGUSR1` and re-read the state file)
- **Implementation**: fish universal variables, `fish_config theme save` and the lsd colors symlink, with validation and logging
- **State management**: Theme persistence in `~/.cache/system-theme.txt`
- **Logging**: Comprehensive logging with rotation in `~/toggle-theme.log`

## Key Configuration Areas

### Development Environment

- **Runtime management**: mise configuration in `dot_config/mise/config.toml.tmpl`
- **Shell**: Fish with custom functions and theme integration
- **Terminal**: Ghostty
- **Git**: Environment-specific signing keys and configurations

### Claude Code Settings

`.chezmoitemplates/claude-settings.json` holds the settings shared by all machines. `dot_claude/modify_settings.json.tmpl`, a jq modify script, overlays it on the live `~/.claude/settings.json` on every `chezmoi apply`: repo keys win, and lists are replaced rather than combined. Keys the repo doesn't own stay as Claude Code and other tools wrote them (`model`, `theme`, `hooks`, `enabledPlugins`, ...), so leave runtime-owned keys out of the repo file. The script records the paths it owns in the target under `_chezmoi_managed` (a top-level key, or `key.subkey` when the repo value is an object, so runtime `env` entries stay untouched); a path dropped from the repo file is deleted from the target on the next apply. Ownership is tracked two levels deep, and owned keys must not contain dots. jq keeps the live key order and Claude Code's 2-space formatting, so a rewrite by Claude Code doesn't show up in `chezmoi status`. The Docker Sandboxes kit (`dot_config/sbx-kits/claude-settings/`) renders the same file into a managed-settings drop-in. Machines use the Claude subscription; set Bedrock or Vertex env vars by hand in the shell when needed.

### System Integration

- **SketchyBar**: Complete SbarLua configuration with modular architecture (`init.lua`, `bar.lua`, `default.lua`, items/\*). Includes window manager integration (Rift), custom items (battery, network, clock, volume, meal planning), and theme coordination. Coding agents can use the deepwiki mcp to retrieve information about [SketchyBar](https://deepwiki.com/FelixKratz/SketchyBar) and [SbarLua](https://deepwiki.com/FelixKratz/SbarLua).
- **Window Manager**: Rift - BSP tiling window manager with Mach IPC. Configuration in `dot_config/rift/config.toml`. Uses CLI subscriptions to trigger SketchyBar updates on workspace/window changes.
- **Teams call PiP**: `rift-pip-auto` runs on Rift's `workspace_changed`/`windows_changed` CLI subscriptions. It finds a Microsoft Teams call window (any Teams window whose title is not a main-window section like `Chat | …`) and mirrors it with [rift-pip](https://github.com/acsandmann/rift-pip) while its workspace is hidden; the PiP closes when the workspace is active again or the call ends. rift-pip is built by `dot-services` (component `rift-pip`) with a local patch (`dot_bin/private_src/rift-pip-window-option.patch`) adding `--window <id>`, since upstream only mirrors the focused window. State and log live in `~/.cache/rift-pip/`. Needs Screen Recording permission for the launching app (rift). Machines without rift-pip (the home Mac has no Teams) still fire the hook on every Rift event: it logs the absence once, drops a `rift-pip-missing` marker in the state dir and exits quietly; building it with `dot-services` clears the marker.
- **Network type item**: `dot_bin/sketchybar-network-watcher.swift` (built into an `.app` by `dot-services`; needs Location Services permission to read the SSID on macOS Sequoia+) triggers the SketchyBar `network_info_change` event with `NETWORK_TYPE`, `NETWORK_SSID`, `NETWORK_SSID_HASH` and `NETWORK_SIGNAL` (WiFi signal level 0-4 from the RSSI; CoreWLAN link quality events re-trigger only when the level changes). On WiFi the item icon shows the level as bars. The SketchyBar item only shows the SSID when it is neither one of the device's default networks nor one of the device's known hotspots, both listed per hostname by HMAC-SHA256 hash (keyed by the `hash_salt` secret rendered to `~/.config/dotfiles/hash-salt`) in `dot_config/sketchybar/lib/known_networks.lua` so network names never enter the repo. Generate hashes with `sketchybar-ssid-hash`. Hovering opens a details popup (signal/noise/SNR, Tx rate, channel, Wi-Fi standard, security, IP, router, connected VPNs): `network_type.lua` sends the watcher `SIGUSR1` on open and `SIGUSR2` on close, and only in between does the watcher gather details and trigger `network_details_change` on every link quality event.
- **Tailscale item**: `dot_config/sketchybar/items/tailscale.lua` only loads where a Tailscale CLI exists (app bundle, `/usr/local/bin` or Homebrew). The LaunchAgent `earth.gru.sketchybar-tailscale-watch` (`dot_bin/sketchybar-tailscale-watch`, installed by `dot-services`) streams `tailscale debug watch-ipn`, filters out the per-second engine stats with jq and triggers `tailscale_change` only on state/prefs/netmap/health changes; the item then reads `tailscale status --json`. Icons: dot grid = connected, globe arrow = exit node in use, muted dot square = off. The hover popup shows tailnet, own IP/MagicDNS name, exit node (direct or DERP) with its traffic, peers, home relay, key expiry, health warnings and version. Clicking does nothing.
- **Package management**: Comprehensive Brewfile (~200 work packages, ~215 home packages) with custom taps, MAS automation, and environment-specific tool sets
- **Karabiner**: Custom keyboard modifications in `private_karabiner/`
- **LaunchAgents**: the daemons in this repo are built and loaded by `dot-services` (see below)

### Brewfile Structure & Management

The Brewfile uses hostname-based conditional logic to manage different package sets across environments:

#### Environment Detection

```ruby
hostname = `hostname -s`.strip
is_work = (hostname == "CO-MBP-KC9KQV64V3")
is_home = (hostname == "yobuko")
```

#### Package Organization

- **Custom taps**: Specialized repositories for tools not in homebrew-core
  - `strayer/tap`: Personal tap (patched sketchybar, dock-badge-counter)
- **Fonts**: Nerd fonts and typography packages for terminal/editor use
- **Linters/formatters/LSPs**: Development tools for code quality and IDE integration
- **Terminal entertainment**: Fun terminal applications (cowsay, lolcat)
- **Various tools**: General CLI utilities (should be split into more specific categories)
- **Neovim-related**: Editor-specific dependencies
- **Git tools**: Enhanced Git workflow utilities
- **Container tools**: Docker/container management utilities
- **Keyboard tools**: QMK/hardware development dependencies

#### Environment-Specific Packages

- **Work machine** (`is_work`): Enterprise tools (Azure CLI, Terraform utilities, browser testing)
- **Home machine** (`is_home`): Personal tools (gaming, 3D printing, home automation, creative software)

#### Mac App Store Integration

Uses `mas` command for App Store applications with specific app IDs, also environment-conditional.

#### Adding New Packages

1. Use `brew search` to find package names
2. Use `brew info` to understand package purpose and dependencies
3. Place in appropriate category or create new category if needed
4. Consider if package should be universal, work-only, or home-only
5. For custom taps, add tap declaration before the package
6. Update package counts in documentation when adding significant numbers

### Security & Privacy

- **GPG configuration**: Agent settings with multi-user conflict resolution and smart card support
- **SSH**: Separate configurations for different services with Secretive app integration (home machine)
- **Authentication**: SSH agent socket management for tmux/screen sessions
- **Private files**: Use `private_` prefix for sensitive configurations (Karabiner, SSH keys)
- **Hash salt**: The generic `hash_salt` secret (64 hex chars) is rendered to `~/.config/dotfiles/hash-salt` (0600) via `dot_config/dotfiles/private_hash-salt.tmpl`. Use it as HMAC-SHA256 key whenever the public repo should store only hashes of private strings (e.g. SSIDs in `known_networks.lua`). Rotating it invalidates all stored hashes.

## Working with Templates

When editing `.tmpl` files, common patterns include:

- `{{ if eq .chezmoi.hostname "CO-MBP-KC9KQV64V3" }}` - Work-specific configuration
- `{{ (secret | fromYaml).<key> }}` - Value from the encrypted secrets (see Encrypted Secrets)
- `{{ $id := get .git.identities .chezmoi.hostname }}` - Per-host Git email and signing key from `.chezmoidata/git.yaml`
- `{{ env "HOME" }}` - Environment variable access
- `{{- if eq .chezmoi.hostname "work" }}` - Conditional blocks with whitespace control

Always test template changes with `chezmoi diff` before applying to avoid syntax errors in generated configurations.

## Automation & Integration

### dot-services (daemons and built tools)

`~/.bin/dot-services` builds, installs and restarts everything in this repo that is compiled or runs as a LaunchAgent (macOS only). Never add another `install-*`/`compile-*` script for such a tool; add a component to `dot-services` instead (its header documents the functions a component defines).

| Component | What it is | LaunchAgent |
|---|---|---|
| `display-refresh-fixer` | Swift `.app` built from `dot_bin/display-refresh-fixer.swift` | `earth.gru.display-refresh-fixer` |
| `display-profile-fixer` | Swift `.app` built from `dot_bin/display-profile-fixer.swift` | `earth.gru.display-profile-fixer` |
| `sketchybar-network-watcher` | Swift `.app` built from `dot_bin/sketchybar-network-watcher.swift` | none, SketchyBar spawns it (restart = `sketchybar --reload`) |
| `sketchybar-tailscale-watch` | shell script, skipped without a Tailscale CLI | `earth.gru.sketchybar-tailscale-watch` |
| `rift-log-rotate` | `rift-log-rotate.sh rotate` every 5 minutes | `com.grunewaldt.rift-log-rotate` |
| `rift-pip` | cargo build of a pinned upstream commit plus the local patch, into `~/.cargo/bin` | none, `rift-pip-auto` starts it |
| `ssh-agent-multiplexer` | pinned, checksum-verified release download into `~/.local/bin` | `local.ssh-agent-multiplexer` |

```bash
dot-services                          # status: enabled for this host, build state, running
dot-services install [--force] [NAME…]  # build/install/restart what changed; no names = this host's list
dot-services restart NAME…
dot-services uninstall NAME…          # stop it and remove plist, artifact and stamps
```

- **Per host**: `.chezmoidata/services.yaml` lists the components each hostname runs; chezmoi renders the list to `~/.config/dotfiles/services`. `status` flags a component that is installed but no longer listed; removing it is a manual `dot-services uninstall`.
- **Idempotent**: a component is rebuilt only when its build stamp (hash of sources and build recipe, kept in `~/.cache/dot-services/`) differs or its artifact is missing. A LaunchAgent is reloaded when the generated plist differs from the installed one and restarted when something it runs changed. Everything else is left alone.
- **Triggered by chezmoi**: `.chezmoiscripts/run_onchange_after_30-dot-services.sh.tmpl` runs `dot-services install` when `dot-services` itself, the host list or a component input changes, so editing a `.swift` source and running `chezmoi apply` rebuilds and restarts just that daemon. A new input file must be added to the list in that template. A build error fails the apply, which makes chezmoi retry on the next one. A missing prerequisite (cargo, Tailscale) only skips that component; the hook hashes their presence and runs again once they exist. `chezmoi apply <target>` and `--exclude scripts` don't run the hook: use `dot-services install` then.
- **Not covered**: SbarLua (`install-sbarlua.sh`, part of the SketchyBar setup), rift itself (`rift service install`) and Homebrew services.

The display-refresh-fixer re-applies BetterDisplay's "unexposed" 3008x1692 HiDPI @ 144 Hz mode on the Dell G3223Q after display reconfiguration or wake, because macOS 15.1+ never persists that mode. Target display/mode are plist arguments (`--display`, `--refresh`, set in `dot-services`); log at `~/Library/Logs/display-refresh-fixer.log`; `kill -USR1 <pid>` forces a check. After editing the `.swift` source, `chezmoi apply` rebuilds and restarts it. The compiled `.app` bundle is a build artifact and not managed by chezmoi.

The display-profile-fixer undoes what Dell Display and Peripheral Manager (DDPM) does on every start: it assigns its own ICC files from `~/Applications/DDPM/Profiles/` to Dell monitors. Those files are malformed (the primaries don't add up to the declared white point), so Chromium, Firefox and Electron apps draw white with a cyan cast, and screenshots, which embed the display profile, turn pink in those apps. The daemon reacts to colour profile changes, display changes and wake; it replaces DDPM's sRGB file with the built-in "sRGB IEC61966-2.1" profile, any other DDPM file with the display's default macOS profile, and posts a notification. Profiles picked by hand in System Settings are left alone, and after three replacements within a minute it backs off instead of fighting DDPM in a loop. `--match` changes which profile paths count as unwanted; log at `~/Library/Logs/display-profile-fixer.log`; `kill -USR1 <pid>` forces a check. Notifications only work when launchd (or `open`) starts the bundle; started from a shell, macOS refuses them. It is built and installed the same way.

### Development Workflows

- **Environment bootstrapping**: Use `chezmoi init` with template variable prompts
- **GPG agent conflicts**: Use `restart-gpg-agent.fish` when multiple users conflict
- **SSH key management**: Use `secretive-ssh-keygen` for Secretive app integration

## Third-Party Software References

Coding agents can use the DeepWiki MCP server to retrieve documentation for the following third-party projects used in this repository:

| Software | GitHub Repo | DeepWiki | Config Location | Purpose |
|---|---|---|---|---|
| SketchyBar | [FelixKratz/SketchyBar](https://github.com/FelixKratz/SketchyBar) | [deepwiki.com/FelixKratz/SketchyBar](https://deepwiki.com/FelixKratz/SketchyBar) | `dot_config/sketchybar/` | Custom macOS status bar |
| SbarLua | [FelixKratz/SbarLua](https://github.com/FelixKratz/SbarLua) | [deepwiki.com/FelixKratz/SbarLua](https://deepwiki.com/FelixKratz/SbarLua) | `dot_config/sketchybar/` | Lua API for SketchyBar |
| Rift | [acsandmann/rift](https://github.com/acsandmann/rift) | [deepwiki.com/acsandmann/rift](https://deepwiki.com/acsandmann/rift) | `dot_config/rift/config.toml` | BSP tiling window manager |

Usage: `mcp__deepwiki__ask_question` with `repoName` set to the GitHub repo (e.g., `"acsandmann/rift"`) and a relevant `question`.

## Conventional Commit Guidelines

- Use conventional commit message format for all commits
- Common scopes based on repository files:
  - `Brewfile`: Package management updates
  - `fish`: Fish shell configurations
  - `ghostty`: Terminal emulator config
  - `sketchybar`: Status bar configuration
  - `mise`: Runtime version management
  - `git`, `gitconfig`: Git configuration
  - `claude`: Claude Code settings
  - `agents`: Shared agent instructions and skills (`.chezmoitemplates/agents.md`, `dot_agents/`)
  - `karabiner`: Keyboard customization
  - `terminal`: Cross-terminal features
  - `atuin`: Command history settings
  - `chezmoi`: Dotfiles management
  - `bin`: Custom scripts in ~/.bin/
  - `raycast`: Launcher scripts in `~/.bin/raycast-scripts` (imported by Tinycast)
- Type usage patterns:
  - `feat`: New features or additions (most common)
  - `fix`: Bug fixes or corrections
  - `chore`: Maintenance, updates without functional changes
  - `refactor`: Code restructuring without behavior changes
  - `docs`: Documentation updates
  - `style`: Formatting, cosmetic changes
  - `perf`: Performance improvements
  - `test`: Testing-related changes
  - `ci`: CI/CD configurations
- Format: `<type>(<scope>): <description>`
  - Scope is optional for general changes (e.g., `chore: add CLAUDE.md`)
  - Use present tense, imperative mood
  - Keep descriptions concise and specific
