#zmodload zsh/zprof

export ZPLUG_HOME=$HOME/.zplug
source $ZPLUG_HOME/init.zsh

prependpath() {
  PATH="$1:$PATH"
}

# Autoescape pasted URLs
autoload -Uz bracketed-paste-url-magic
zle -N bracketed-paste bracketed-paste-url-magic

# nvm-zsh configuration
export NVM_AUTO_USE=true
export NVM_LAZY_LOAD=true

zplug "zsh-users/zsh-completions"
zplug "psprint/history-search-multi-word"
zplug "jreese/zsh-titles"

zplug mafredri/zsh-async, from:github
zplug sindresorhus/pure, use:pure.zsh, from:github, as:theme

zplug "zsh-users/zsh-autosuggestions"

#zplug "lukechilds/zsh-nvm", if: "[[ \"$HOST\" == Musashi ]]"

zplug "zsh-users/zsh-syntax-highlighting", defer:2 # should be 2nd last
zplug "zsh-users/zsh-history-substring-search", defer:2 # Should be loaded last.

# Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# Then, source plugins and add commands to $PATH
zplug load

# ZSH history
setopt append_history
setopt hist_expire_dups_first
setopt hist_fcntl_lock
setopt hist_ignore_all_dups
setopt hist_lex_words
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt share_history

# don't save commands beginning with a space to the command history
setopt hist_ignore_space

export HISTSIZE=11000
export SAVEHIST=10000
export HISTFILE=~/.zsh_history

# Keybinding overrides for iTerm hotkeys
bindkey "^U" backward-kill-line
bindkey "^X^_" redo

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
if [[ -x "/usr/local/bin/vim" ]]; then
  alias vim="/usr/local/bin/vim"
  alias vimtutor="/usr/local/bin/vimtutor"
  alias vimdiff="/usr/local/bin/vimdiff"
fi

# File stuff
alias ls="${GNU_TOOLS_PREFIX}ls --color=auto"
alias l="ls -lav --time-style=long-iso"
alias du="${GNU_TOOLS_PREFIX}du -k"

# Helper aliases
alias gpgcat="gpg -q -d"
alias treesize="${GNU_TOOLS_PREFIX}du -shx ./* ./.* | ${GNU_TOOLS_PREFIX}sort -rh"
if [[ -x "/usr/local/bin/brew" ]]; then
  alias brup="brew up && brew upgrade && brew cleanup && brew cask cleanup && brew cask outdated"
fi
if command -v tmux >/dev/null 2>/dev/null; then
  alias tm='tmux attach || tmux new'
fi

VMWARE_VDISKMANAGER=/Applications/VMware\ Fusion.app/Contents/Library/vmware-vdiskmanager
if [[ -x "$VMWARE_VDISKMANAGER" ]]; then
  alias vmware-vdiskmanager="'$VMWARE_VDISKMANAGER'"
fi

# pyenv
if command -v pyenv >/dev/null 2>/dev/null; then
  # Disable pyenv prompt handling (handled by zsh)
  export PYENV_VIRTUALENV_DISABLE_PROMPT=1

  eval "$(pyenv init -)"
  eval "$(pyenv virtualenv-init -)"
fi

# Load NVS
export NVS_HOME="$HOME/.nvs"
[ -s "$NVS_HOME/nvs.sh" ] && . "$NVS_HOME/nvs.sh" && nvs auto on

#if command -v rbenv >/dev/null 2>/dev/null; then
#  eval "$(rbenv init -)"
#fi

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

if [[ "$HOST" = "wolf359" && "$USER" = "strayer" ]]; then
  # Make sure gpg-agent is running so SSH can use its agent
  #if command -v gpgconf >/dev/null 2>/dev/null; then
    #gpgconf --launch gpg-agent >/dev/null
  #fi

  # Use GPGs ssh-agent compatibility
  #export SSH_AUTH_SOCK="${HOME}/.gnupg/S.gpg-agent.ssh"
fi

# Config
if [[ -e "$HOME/.homebrew-github-token" ]]; then
  export HOMEBREW_GITHUB_API_TOKEN="$(<$HOME/.homebrew-github-token)"
fi
if command -v brew >/dev/null 2>/dev/null; then
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_NO_AUTO_UPDATE=1
fi

export EDITOR="vim"

if [[ -d "/usr/local/sbin" ]]; then
  prependpath "/usr/local/sbin"
fi

# Local software & scripts
if [[ -d "$HOME/.bin" ]]; then
  prependpath $HOME/.bin
fi

# Fastlane
if [[ -d "$HOME/.fastlane/bin" ]]; then
  export FASTLANE_OPT_OUT_USAGE=1
  prependpath "$HOME/.fastlane/bin"
fi

# mpv
if command -v mpv >/dev/null 2>/dev/null; then
  alias mpv-vp9="mpv --ytdl-format=\"bestvideo[ext=webm]+bestaudio\""
fi

# Neofetch
if command -v neofetch >/dev/null 2>/dev/null; then
	echo ""
	neofetch
fi

# React Native
if command -v react-native >/dev/null 2>/dev/null; then
	alias "r-n"="react-native"
fi

# direnv
if command -v direnv >/dev/null 2>/dev/null; then
  eval "$(direnv hook zsh)"
fi

# Load all files from .shell/zshrc.d directory
if test -n "$(find $HOME/.zshrc.d/ -maxdepth 1 -name '*.zsh' -print -quit)"; then
	for file in $HOME/.zshrc.d/*.zsh; do
		source $file
	done
fi

bindkey "^[f" forward-word
bindkey "^[b" backward-word

# Force unique values for path array ($PATH is tied to path in zsh)
# https://unix.stackexchange.com/a/62599
typeset -U path

