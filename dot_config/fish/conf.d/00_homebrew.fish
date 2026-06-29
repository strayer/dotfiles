# Make sure Homebrew is in PATH and the full Homebrew env (HOMEBREW_PREFIX,
# MANPATH, INFOPATH, ...) is set on both macOS (/opt/homebrew) and Linuxbrew
# (/home/linuxbrew/.linuxbrew or ~/.linuxbrew).
if test -e /opt/homebrew/bin/brew
  eval (/opt/homebrew/bin/brew shellenv)
else if test -e /home/linuxbrew/.linuxbrew/bin/brew
  eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
else if test -e "$HOME/.linuxbrew/bin/brew"
  eval ("$HOME/.linuxbrew/bin/brew" shellenv)
end

# Don't upgrade casks that update themselves
set -gx HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS 1
