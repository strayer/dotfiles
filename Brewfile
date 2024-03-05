hostname = `hostname -s`.strip
is_work = (hostname == "CO-MBP-KC9KQV64V3")
is_home = (hostname == "yobuko")

# base taps
tap "homebrew/bundle"
tap "homebrew/cask-versions"

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

# fonts
tap "homebrew/cask-fonts"
cask "font-iosevka"
cask "font-iosevka-nerd-font"
cask "font-monocraft"
cask "font-symbols-only-nerd-font"

# linters, formatters
brew "yamllint"
brew "ansible-lint"
brew "hadolint"
brew "tflint"
brew "shfmt"

# various tools (I should split this into sections...)
brew "aria2"
brew "atuin"
brew "bat"
brew "bgpq3"
brew "bind" # for dig, nslookup and host
brew "bottom"
brew "cmake"
brew "colordiff"
brew "coreutils"
brew "csvkit"
brew "direnv"
brew "dos2unix"
brew "exiftool"
brew "fd"
brew "findutils"
brew "fish"
brew "fzf"
brew "gnu-tar"
brew "gnu-sed"
brew "go"
brew "gopass"
brew "gotop"
brew "gping"
brew "grep"
brew "htop"
brew "httpie"
brew "httping"
brew "httpstat"
brew "influxdb"
brew "iperf"
brew "iperf3"
brew "iproute2mac"
brew "jq"
brew "lolcat"
brew "lsd"
brew "mosh"
brew "mpv"
brew "mtr"
brew "ncdu"
brew "netcat"
brew "netperf"
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
brew "prettyping"
brew "procs"
brew "pwgen"
brew "ranger"
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
brew "trivy"
brew "watch"
brew "wget"
brew "yadm"
brew "yarn"
brew "yazi"
brew "yq"
brew "yt-dlp"
brew "zbar"
brew "zoxide"

# neovim-related
brew "luarocks"
brew "neovim"

# language servers
brew "ruff-lsp"

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
cask "alfred"
cask "android-studio"
cask "avidemux"
cask "bartender"
cask "betterdisplay"
cask "bettertouchtool"
cask "contexts"
cask "coteditor"
cask "daisydisk"
cask "dbeaver-community"
cask "firefox-developer-edition"
cask "gimp"
cask "hex-fiend"
cask "iina"
cask "iterm2"
cask "inkscape"
cask "karabiner-elements"
cask "keka"
cask "kekaexternalhelper"
cask "mediainfo"
cask "mitmproxy"
cask "obsidian"
cask "orbstack"
cask "p4v"
cask "pgadmin4"
cask "powershell"
cask "secretive"
cask "spotify"
cask "stats"
cask "steermouse"
cask "utm"
cask "visual-studio-code"
cask "vlc"
cask "vnc-viewer"
cask "wezterm"
cask "wireshark"

mas "Amphetamine", id: 937984704
mas "Bitwarden", id: 1352778147
mas "Color Picker", id: 1545870783
mas "Discovery", id: 1381004916
mas "Microsoft Remote Desktop", id: 1295203466
mas "Moom", id: 419330170
mas "Negative", id: 1378123825 # Dark mode for PDFs

if is_work then
  tap "heroku/brew"
  brew "heroku/brew/heroku"

  tap "minamijoyo/tfupdate"
  brew "minamijoyo/tfupdate/tfupdate"

  brew "azure-cli"
  brew "step"

  cask "jabra-direct"
  cask "google-chrome"
  cask "microsoft-edge"
  cask "anypointstudio"
  cask "flameshot"
end

if is_home then
  tap "cloudflare/cloudflare"
  cask "cf-terraforming"

  brew "hcloud"
  brew "wireguard-tools"

  cask "1password"
  cask "1password-cli"
  cask "balenaetcher"
  cask "brave-browser-beta"
  cask "calibre"
  cask "discord"
  cask "itsycal"
  cask "kicad"
  cask "macfuse"
  cask "mumble"
  cask "openscad"
  cask "parsec"
  cask "plex"
  cask "prismlauncher"
  cask "prusaslicer"
  cask "raspberry-pi-imager"
  cask "signal"
  cask "steam"
  cask "syncthing"
  cask "thunderbird-beta"
  cask "todoist"
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
  mas "Tailscale", id: 1475387142
  mas "Telegram", id: 747648890
  mas "WireGuard", id: 1451685025
end

# vim: ft=ruby
