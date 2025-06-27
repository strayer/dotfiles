hostname = `hostname -s`.strip
is_work = (hostname == "CO-MBP-KC9KQV64V3")
is_home = (hostname == "yobuko")

# base taps
tap "homebrew/bundle"
tap "homebrew/services"

# mas
brew "mas"

# speedtest-cli
tap "teamookla/speedtest"
brew "teamookla/speedtest/speedtest"

# curlie
tap "rs/tap"
brew "rs/tap/curlie"

# dyff
tap "homeport/tap"
brew "homeport/tap/dyff"

# litra cli
tap "timrogers/tap"
brew "litra"

# felixkratz tools
tap "felixkratz/formulae"
brew "felixkratz/formulae/borders"
brew "felixkratz/formulae/sketchybar"

# aerospace
tap "nikitabobko/tap"
cask "nikitabobko/tap/aerospace"

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

# linters, formatters, LSPs
brew "ansible-lint"
brew "basedpyright"
brew "bash-language-server"
brew "dockerfile-language-server"
brew "hadolint"
brew "lua-language-server"
brew "markdownlint-cli"
brew "markdownlint-cli2"
brew "prettierd"
brew "ruff"
brew "ruff-lsp"
brew "shfmt"
brew "stylua"
brew "taplo"
brew "terraform-ls"
brew "tflint"
brew "yaml-language-server"
brew "yamllint"

# various tools (I should split this into sections...)
brew "age"
brew "age-plugin-se"
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
brew "influxdb"
brew "iperf"
brew "iperf3"
brew "iproute2mac"
brew "jpegoptim"
brew "jq"
brew "just"
brew "lftp"
brew "lolcat"
brew "lsd"
brew "mise"
brew "mosh"
brew "mpv"
brew "mtr"
brew "ncdu"
brew "netcat"
brew "netperf"
brew "ollama"
brew "openjdk"
brew "openssh"
brew "optipng"
brew "oxipng"
brew "p7zip"
brew "parallel"
brew "pass-otp"
brew "pdf2svg"
brew "pigz"
brew "pinentry-mac"
brew "pipx"
brew "pixz"
brew "pngpaste"
brew "pnpm"
brew "pre-commit"
brew "prettyping"
brew "procs"
brew "pwgen"
brew "ranger"
brew "rclone"
brew "repomix"
brew "restic"
brew "ripgrep"
brew "rsync"
brew "sevenzip"
brew "shellcheck"
brew "socat"
brew "starship"
brew "svgo"
brew "taglib"
brew "tealdeer"
brew "telnet"
brew "testssl"
brew "tmux"
brew "trivy"
brew "uv"
brew "watch"
brew "wget"
brew "xh"
brew "yarn"
brew "yazi"
brew "yq"
brew "yt-dlp"
brew "zbar"
brew "zoxide"

# neovim-related
brew "luarocks"
brew "neovim"

# better git
brew "diff-so-fancy"
brew "gh"
brew "git"
brew "git-delta"
brew "git-trim"
brew "lazygit"

# container stuff
brew "dive"

# keyboard-related
brew "platformio"
brew "dfu-util"

# casks
cask "android-studio"
cask "app-tamer"
cask "avidemux"
cask "betterdisplay"
cask "bettertouchtool"
cask "brave-browser@beta"
cask "bruno"
cask "clop"
cask "contexts"
cask "coteditor"
cask "daisydisk"
cask "db-browser-for-sqlite"
cask "dbeaver-community"
cask "firefox@developer-edition"
cask "ghostty"
cask "gimp"
cask "google-cloud-sdk"
cask "hex-fiend"
cask "iina"
cask "inkscape"
cask "iterm2"
cask "jordanbaird-ice"
cask "karabiner-elements"
cask "keka"
cask "kekaexternalhelper"
cask "kitty"
cask "lm-studio"
cask "logitune"
cask "marta"
cask "mediainfo"
cask "mitmproxy"
cask "moom"
cask "neovide-app"
cask "obsidian"
cask "orbstack"
cask "p4v"
cask "pgadmin4"
cask "powershell"
cask "qlmarkdown"
cask "raycast"
cask "secretive"
cask "shottr"
cask "skim"
cask "spotify"
cask "stats"
cask "steermouse"
cask "swiftbar"
cask "swiftdefaultappsprefpane"
cask "upscayl"
cask "utm"
cask "visual-studio-code"
cask "vlc"
cask "vnc-viewer"
cask "wezterm@nightly"
cask "wireshark-app"
cask "zen"

mas "Amphetamine", id: 937984704
mas "Bitwarden", id: 1352778147
mas "Color Picker", id: 1545870783
mas "Discovery", id: 1381004916
mas "Microsoft Remote Desktop", id: 1295203466
mas "Negative", id: 1378123825 # Dark mode for PDFs

if is_work then
  tap "heroku/brew"
  brew "heroku/brew/heroku"

  tap "minamijoyo/tfupdate"
  brew "minamijoyo/tfupdate/tfupdate"

  tap "garethgeorge/backrest-tap"
  brew "garethgeorge/backrest-tap/backrest"

  tap "azure/functions"
  brew "azure/functions/azure-functions-core-tools@4"

  brew "azcopy"
  brew "azure-cli"
  brew "bitwarden-cli"
  brew "pandoc"
  brew "step"

  cask "anypointstudio"
  cask "deepl"
  cask "flameshot"
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

if is_home then
  tap "cloudflare/cloudflare"
  cask "cf-terraforming"

  brew "ansible"
  brew "esptool"
  brew "hcloud"
  brew "rclone"
  brew "wireguard-tools"

  cask "1password"
  cask "1password-cli"
  cask "android-platform-tools"
  cask "autodesk-fusion"
  cask "balenaetcher"
  cask "bambu-studio"
  cask "betterzip"
  cask "calibre"
  cask "diffusionbee"
  cask "discord"
  cask "flux-app"
  cask "freecad"
  cask "itsycal"
  cask "kicad"
  cask "macfuse"
  cask "mqtt-explorer"
  cask "mumble"
  cask "obs"
  cask "openmw"
  cask "openscad"
  cask "orcaslicer"
  cask "parsec"
  cask "plex"
  cask "prismlauncher"
  cask "prusaslicer"
  cask "raspberry-pi-imager"
  cask "signal"
  cask "steam"
  cask "syncthing-app"
  cask "tailscale-app"
  cask "thunderbird@beta"
  cask "todoist-app"
  cask "tor-browser"
  cask "veracrypt"
  cask "vmware-fusion"
  cask "yubico-yubikey-manager"

  mas "1Password for Safari", id: 1569813296
  mas "Brother P-touch Editor", id: 1453365242
  mas "CrystalFetch", id: 6454431289 # Download Windows images from microsoft.com
  mas "Microsoft Word", id: 462054704
  mas "Goodnotes", id: 1444383602
  mas "Home Assistant", id: 1099568401
  mas "OneDrive", id: 823766827
  mas "Prime Video", id: 545519333
  mas "Telegram", id: 747648890
  mas "WireGuard", id: 1451685025
end

# vim: ft=ruby
