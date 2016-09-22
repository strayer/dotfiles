export ZPLUG_HOME=$HOME/.zplug
source $ZPLUG_HOME/init.zsh

# Force unique values for path array ($PATH is tied to path in zsh)
# https://unix.stackexchange.com/a/62599
typeset -U path

prependpath() {
  path=($1 "$path[@]")
}

zplug "zsh-users/zsh-completions"
zplug "psprint/history-search-multi-word"

zplug "bhilburn/powerlevel9k", use:powerlevel9k.zsh-theme, at:next

zplug "zsh-users/zsh-autosuggestions"

zplug "zsh-users/zsh-syntax-highlighting", nice:18 # should be 2nd last
zplug "zsh-users/zsh-history-substring-search", nice:19 # Should be loaded last.

# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# Then, source plugins and add commands to $PATH
zplug load --verbose

# ZSH history
setopt append_history
setopt hist_expire_dups_first
setopt hist_fcntl_lock
setopt hist_ignore_all_dups
setopt hist_lex_words
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt share_history

export HISTSIZE=11000
export SAVEHIST=10000
export HISTFILE=~/.zsh_history

# powerline9k theme

if zplug check bhilburn/powerlevel9k; then
  POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs virtualenv status)

  if [[ "$HOST" == "Musashi" && "$USER" == "strayer" ]]; then
    POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=("${POWERLEVEL9K_LEFT_PROMPT_ELEMENTS[@]:1}")
  fi

  if [[ "$HOST" == "valaskjalf" ]]; then
    POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND="010"
    POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND="001"
  fi

  if [[ "$HOST" == "PC0164" ]]; then
    POWERLEVEL9K_CONTEXT_DEFAULT_FOREGROUND="012"
  fi

  POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()

  POWERLEVEL9K_TIME_FORMAT="%D{%H:%M:%S %d.%m.%y}"

  POWERLEVEL9K_SHORTEN_DIR_LENGTH=5
  POWERLEVEL9K_SHORTEN_DELIMITER="…"
  POWERLEVEL9K_SHORTEN_STRATEGY="truncate_middle"

  POWERLEVEL9K_STATUS_VERBOSE=false

  POWERLEVEL9K_PROMPT_ON_NEWLINE=true
  POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""
  POWERLEVEL9K_MULTILINE_SECOND_PROMPT_PREFIX="$ "
fi

# Bind UP and DOWN arrow keys for subsstring search.
if zplug check zsh-users/zsh-history-substring-search; then
  zmodload zsh/terminfo
  bindkey "$terminfo[kcuu1]" history-substring-search-up
  bindkey "$terminfo[kcud1]" history-substring-search-down
fi

# 0 -- vanilla completion (abc => abc)
# 1 -- smart case completion (abc => Abc)
# 2 -- word flex completion (abc => A-big-Car)
# 3 -- full flex completion (abc => ABraCadabra)
# Source: https://superuser.com/a/815317/40285
zstyle ':completion:*' matcher-list '' \
  'm:{a-z\-}={A-Z\_}' \
  'r:[^[:alpha:]]||[[:alpha:]]=** r:|=* m:{a-z\-}={A-Z\_}' \
  'r:[[:ascii:]]||[[:ascii:]]=** r:|=* m:{a-z\-}={A-Z\_}'

# GNU tools prefix (required for macOS with Homebrew coreutils)
GNU_TOOLS_PREFIX=""
if [[ -d "/usr/local/opt/coreutils/libexec/gnubin" ]]; then
  GNU_TOOLS_PREFIX="g"
fi

# Local software installations
if [[ -x "/usr/local/bin/nano" ]]; then
  alias nano="/usr/local/bin/nano"
fi
if [[ -x "/usr/local/bin/ssh" ]]; then
  alias ssh="/usr/local/bin/ssh"
fi
if [[ -x "/usr/local/bin/gfind" ]]; then
  alias find="gfind"
fi

# File stuff
alias ls="${GNU_TOOLS_PREFIX}ls --color=auto"
alias l="ls -lav --time-style=long-iso"
alias du="${GNU_TOOLS_PREFIX}du -k"

# Helper aliases
alias gpgcat="gpg -q -d"
alias treesize="${GNU_TOOLS_PREFIX}du -shx ./* | ${GNU_TOOLS_PREFIX}sort -rh"
if [[ -x "/usr/local/bin/brew" ]]; then
  alias brup="brew up && brew upgrade && brew cleanup"
fi
if command -v tmux >/dev/null 2>/dev/null; then
  alias tm='tmux attach || tmux new'
fi

VMWARE_VDISKMANAGER="/Applications/VMware\ Fusion.app/Contents/Library/vmware-vdiskmanager"
if [[ -x VMWARE_VDISKMANAGER ]]; then
  alias vmware-vdiskmanager=VMWARE_VDISKMANAGER
fi

# pyenv
if command -v pyenv >/dev/null 2>/dev/null; then
  # Disable pyenv prompt handling (handled by zsh)
  export PYENV_VIRTUALENV_DISABLE_PROMPT=1

  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

# Android
if [[ -d $HOME/Library/Android/sdk ]]; then
  export ANDROID_HOME=$HOME/Library/Android/sdk
  prependpath $ANDROID_HOME/platform-tools
  prependpath $ANDROID_HOME/tools
fi

# Gentoo-specific stuff on valaskjalf
if [[ "$HOST" = "valaskjalf" && "$USER" = "root" ]]; then
  # Emerge will fail when exact package and version is given due to feature of
  # zsh which treats "=" differently compared to bash. To make
  # emerge =<pkg>-<version> work, (un)set:
  unsetopt equals

  alias squashmount='noglob squashmount'
  alias esync="eix-sync && squashmount remount portage && squashmount remount layman"
  alias equery="noglob equery"
fi

# Config
if [[ -e "$HOME/.homebrew-github-token" ]]; then
  export HOMEBREW_GITHUB_API_TOKEN="$(<$HOME/.homebrew-github-token)"
fi
if command -v brew >/dev/null 2>/dev/null; then
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_NO_AUTO_UPDATE=1
fi

export EDITOR="nano"

if [[ -d "/usr/local/sbin" ]]; then
  prependpath "/usr/local/sbin"
fi

# Local software & scripts
if [[ -d "$HOME/.bin" ]]; then
  prependpath $HOME/.bin
fi
