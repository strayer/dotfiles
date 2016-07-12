export ZPLUG_HOME=/usr/local/opt/zplug
source $ZPLUG_HOME/init.zsh

zplug "zsh-users/zsh-completions"
zplug "psprint/history-search-multi-word"
zplug "zlsun/solarized-man"

zplug "bhilburn/powerlevel9k", use:powerlevel9k.zsh-theme

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
  if [[ "$HOST" = "Musashi" && "$USER" = "strayer" ]]; then
    POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)
  else
    POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs)
  fi
  POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status virtualenv time)

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

# Disable pyenv prompt handling (handled by zsh)
export PYENV_VIRTUALENV_DISABLE_PROMPT=1

# File stuff
alias ls="gls --color=auto"
alias l="ls -lav --time-style=long-iso"
alias du="du -k"

# Homebrew dupes
alias find="gfind"
alias nano="/usr/local/bin/nano"
alias ssh="/usr/local/bin/ssh"

# Helper aliases
alias gpgcat="gpg -q -d"
alias treesize="gdu -shx ./* | gsort -rh"
alias brup="brew up && brew upgrade && brew cleanup"
alias vmware-vdiskmanager="/Applications/VMware\ Fusion.app/Contents/Library/vmware-vdiskmanager"

# Python
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Android
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$PATH

# Config
export HOMEBREW_GITHUB_API_TOKEN=***REMOVED***

# Local software & scripts
export PATH=$HOME/.bin:$PATH
