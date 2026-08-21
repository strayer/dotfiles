hostname = `hostname -s`.strip

# role (platform comes from Homebrew's OS.mac? / OS.linux? helpers inline below)
is_work = ["CO-MBP-KC9KQV64V3", "DEMUE1M1602"].include?(hostname)  # work macOS or Linux/WSL
is_home = (hostname == "yobuko")                                   # personal (always macOS)

# =============================================================================
# Universal CLI tools (macOS + Linux via Linuxbrew)
# =============================================================================

# AI
brew "agent-browser"
brew "nono"
brew "llm"
brew "opencode"
cask "claude-code@latest"  # cask has linux binaries (x86_64 + arm64)
cask "codex"               # same

# linters, formatters, LSPs
brew "ansible-lint"
brew "basedpyright"
brew "bash-language-server"
brew "dockerfile-language-server"
brew "gopls"
brew "hadolint"
brew "lua-language-server"
brew "markdownlint-cli"
brew "markdownlint-cli2"
brew "prettierd"
brew "ruff"
brew "rust-analyzer"
brew "shfmt"
brew "stylua"
brew "taplo"
brew "terraform-ls"
brew "tflint"
brew "tofu-ls"
brew "vtsls"
brew "yaml-language-server"
brew "yamllint"

# terminal entertainment
brew "asciiquarium"
brew "cbonsai"
brew "lolcat"
brew "pipes-sh"

# various tools (I should split this into sections...)
brew "age"
brew "age-plugin-yubikey"
brew "aichat"
brew "aria2"
brew "asciinema"
brew "atuin"
brew "autossh"
brew "awscli"
brew "bat"
brew "bgpq3"
brew "bind" # for dig, nslookup and host
brew "bottom"
brew "chafa"
brew "chezmoi"
brew "cmake"
brew "colordiff"
brew "coreutils"
brew "cosign" # used by mise
brew "csvkit"
brew "csvlens"
brew "curl"
brew "direnv"
brew "doggo"
brew "dos2unix"
brew "dprint"
brew "efm-langserver"
brew "exiftool"
brew "fastfetch"
brew "fd"
brew "findutils"
brew "fish"
brew "fzf"
brew "glow"  # CLI markdown viewer
brew "gnu-sed"
brew "gnu-tar"
brew "go"
brew "gopass"
brew "gotop"
brew "gping"
brew "grep"
brew "gron"
brew "htop"
brew "httpie"
brew "httping"
brew "httpstat"
brew "iperf"
brew "iperf3"
brew "jpegoptim"
brew "jq"
brew "just"
brew "lftp"
brew "lsd"
brew "mise"
brew "mosh"
brew "mpv"
brew "mtr"
brew "ncdu"
brew "netcat"
brew "openjdk"
brew "openssh"
brew "optipng"
brew "oxipng"
brew "p7zip"
brew "pandoc"
brew "parallel"
brew "pass-otp"
brew "pdf2svg"
brew "pigz"
brew "pipx"
brew "pixz"
brew "pnpm"
brew "powershell"
brew "pre-commit"
brew "prek"
brew "prettyping"
brew "procs"
brew "pwgen"
brew "ranger"
brew "rclone"
brew "repomix"
brew "restic"
brew "ripgrep"
brew "rsync"
brew "rust"
brew "sevenzip"
brew "shellcheck"
brew "socat"
brew "sops"
brew "starship"
brew "svgo"
brew "taglib"
brew "tealdeer"
brew "testssl"
brew "tmux"
brew "trivy"
brew "uv"
brew "watch"
brew "wget"
brew "xh"
brew "yazi"
brew "yq"
brew "yt-dlp"
brew "zbar"
brew "zoxide"

# neovim-related
brew "luarocks"
brew "neovim"
brew "tree-sitter-cli"

# better git
brew "diff-so-fancy"
brew "gh"
brew "git"
brew "git-delta"
brew "git-trim"
brew "lazygit"

# container stuff
brew "dive"

# work CLI (cross-platform; installs on work macOS and work Linux)
if is_work
  tap "minamijoyo/tfupdate"
  brew "minamijoyo/tfupdate/tfupdate", trusted: true

  tap "garethgeorge/backrest-tap"
  brew "garethgeorge/backrest-tap/backrest", trusted: true

  brew "azcopy"
  brew "azure-cli"
  brew "bitwarden-cli"
  brew "step"
end

# =============================================================================
# macOS only (formulae requiring macOS, casks, Mac App Store)
# =============================================================================
if OS.mac?
  # mas (Mac App Store CLI)
  brew "mas"

  # homebrew autoupdate (launchd-based)
  tap "domt4/autoupdate", trusted: { command: "autoupdate" }

  # felixkratz tools (status bar + window borders)
  tap "felixkratz/formulae"
  brew "felixkratz/formulae/borders", trusted: true
  brew "felixkratz/formulae/sketchybar", trusted: true

  # rift (BSP tiling window manager)
  tap "acsandmann/tap"
  brew "acsandmann/tap/rift", trusted: true

  # AI
  brew "ollama"

  # sbx (Docker Sandboxes, agent sandbox launcher; arm64 macOS 14+ only)
  tap "docker/tap", trusted: { cask: "sbx" }
  cask "sbx"

  # macOS-only CLI (hard macOS requirement)
  brew "age-plugin-se" # Secure Enclave age plugin
  brew "iproute2mac"
  brew "pinentry-mac"
  brew "pngpaste"
  brew "telnet"  # the formula is macOS-only; Linux gets inetutils via apt

  # litra cli
  brew "litra"

  # keyboard-related
  brew "platformio"
  brew "dfu-util"

  # fonts
  cask "font-iosevka"
  cask "font-liberation"
  cask "font-iosevka-nerd-font"
  cask "font-monocraft"
  cask "font-roboto"
  cask "font-roboto-mono"
  cask "font-roboto-serif"
  cask "font-sketchybar-app-font"
  cask "font-symbols-only-nerd-font"

  # casks
  cask "android-studio"
  cask "app-tamer"
  cask "avidemux"
  cask "brave-browser@beta"
  cask "bruno"
  cask "chatgpt"  # replaces discontinued codex-app; Codex agent management lives here now
  cask "claude"  # Claude desktop app (claude-code@latest above is the CLI)
  cask "clop"
  cask "contexts"
  cask "coteditor"
  cask "daisydisk"
  cask "db-browser-for-sqlite"
  cask "dbeaver-community"
  cask "firefox@developer-edition"
  cask "gcloud-cli"
  cask "ghostty"
  cask "gimp"
  cask "hex-fiend"
  cask "iina"
  cask "inkscape"
  cask "iterm2"
  cask "karabiner-elements"
  cask "kitty"
  cask "libreoffice"
  cask "lm-studio"
  cask "logitune"
  cask "mediainfo"
  cask "mitmproxy"
  cask "obsidian"
  cask "orbstack"
  cask "p4v"
  cask "pgadmin4"
  cask "raycast"
  cask "secretive"
  cask "shottr"
  cask "spotify"
  cask "steermouse"
  cask "swiftdefaultappsprefpane"
  cask "upscayl"
  cask "utm"
  cask "visual-studio-code"
  cask "vlc"
  cask "vnc-viewer"
  cask "wezterm@nightly"
  cask "wireshark-app"
  cask "yubico-authenticator"
  cask "zen"

  mas "Amphetamine", id: 937984704
  mas "Balance Lock", id: 1019371109
  mas "Bitwarden", id: 1352778147
  mas "Brother P-touch Editor", id: 1453365242
  mas "Color Picker", id: 1545870783
  mas "CrystalFetch", id: 6454431289 # Download Windows images from microsoft.com
  mas "Discovery", id: 1381004916
  mas "Microsoft Remote Desktop", id: 1295203466
  mas "Negative", id: 1378123825 # document/PDF reader with color inversion for reading in the dark
  mas "uBlock Origin Lite", id: 6745342698
  # mas "Xcode", id: 497799835 # exclude for now, using beta because of beta macOS

  # work GUI apps (macOS only)
  if is_work
    cask "anypointstudio"
    cask "deepl"
    cask "firefox@nightly"
    cask "google-chrome"
    cask "jabra-direct"
    cask "keepassxc"
    cask "microsoft-azure-storage-explorer"
    cask "microsoft-edge"
    cask "miro"
    cask "mongodb-compass"
    cask "postman"
    cask "slack"
  end

  # home (personal, always macOS)
  if is_home
    brew "ansible"
    brew "esptool"
    brew "hcloud"
    brew "rclone"
    brew "spicetify-cli"
    brew "wireguard-tools"

    cask "1password"
    cask "1password-cli"
    cask "android-platform-tools"
    cask "balenaetcher"
    cask "bambu-connect"
    cask "calibre"
    cask "discord"
    cask "freecad"
    cask "kicad"
    cask "macfuse"
    cask "microsoft-auto-update"
    cask "microsoft-excel"
    cask "moonlight"
    cask "mqtt-explorer"
    cask "openscad@snapshot"
    cask "orcaslicer"
    cask "plex"
    cask "raspberry-pi-imager"
    cask "signal"
    cask "steam"
    cask "syncthing-app"
    cask "tailscale-app"
    cask "thunderbird@beta"
    cask "tor-browser"
    cask "veracrypt"

    mas "1Password for Safari", id: 1569813296
    mas "AusweisApp", id: 948660805
    mas "Microsoft Word", id: 462054704
    mas "Goodnotes", id: 1444383602
    mas "Home Assistant", id: 1099568401
    mas "OneDrive", id: 823766827
    mas "Telegram", id: 747648890
    mas "WhatsApp", id: 310633997
  end
end

# vim: ft=ruby
