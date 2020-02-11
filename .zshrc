source ~/.zinit/bin/zinit.zsh

function cmd_exists() {
  (( $+commands[$1] ))
}

# force PATH to have unique values
typeset -U path

# load Nord dircolors
function () {
  local nord_dircolors_path=$HOME/.nord-dircolors/src/dir_colors

  if test -e "$nord_dircolors_path"; then
    cmd_exists gdircolors && eval $(gdircolors $nord_dircolors_path)
    cmd_exists dircolors && eval $(dircolors $nord_dircolors_path)
  fi
}

# khitomer-specific stuff
if [ "${HOST%%.*}" = "khitomer" -a "$USER" = "strayer" ]; then
  export SSH_AUTH_SOCK="$HOME/.gnupg/S.gpg-agent.ssh"

  # Make sure gpg-agent is running so SSH can use its agent
  gpgconf --launch gpg-agent >/dev/null

  # Add /usr/local/sbin to path if it exists
  [ -d "/usr/local/sbin" ] && path=(/usr/local/sbin $path)
fi

# Nord dircolors for BSD ls
# TODO does this actually work with macOS ls?
export LSCOLORS=gxfxbEaEBxxEhEhBaDaCaD

# Set editor
if cmd_exists nvim; then
  export EDITOR=nvim
elif cmd_exists vim; then
  export EDITOR=vim
fi

# force emacs key bindings
set -o emacs

# Local software and scripts
if [ -d "$HOME/.bin" ]; then
  path=("$HOME/.bin" $path)
fi

# asdf
if [ -d "$HOME/.asdf" ]; then
  . $HOME/.asdf/asdf.sh
  function load_asdf_completions() {
    . $HOME/.asdf/completions/asdf.bash
  }
fi

# fzf
if [ -f ~/.fzf.zsh ]; then
  export FZF_TMUX=1
  source ~/.fzf.zsh
fi

# Android SDK
if [ -d "$HOME/Library/Android/sdk" ]; then
  export ANDROID_HOME="$HOME/Library/Android/sdk"
  path=("$ANDROID_HOME/platform-tools" $path)
  path=("$ANDROID_HOME/tools" $path)
fi

# python poetry
if [ -d "$HOME/.poetry" ]; then
  path=("$HOME/.poetry/bin" $path)
fi

# Homebrew
if cmd_exists brew; then
  [ -e "$HOME/.homebrew-github-token" ] && \
      export HOMEBREW_GITHUB_API_TOKEN="$(cat $HOME/.homebrew-github-token)"

  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_NO_AUTO_UPDATE=1
  export HOMEBREW_INSTALL_CLEANUP=1
fi

# Disable cowsay for ansible
if cmd_exists ansible; then
  export ANSIBLE_NOCOWS=1
fi

# direnv
if cmd_exists direnv; then
  eval "$(direnv hook zsh)"
fi

# fasd
cmd_exists fasd && eval "$(fasd --init auto)"

# Add .local/bin to PATH (used by Python)
[ -d "$HOME/.local/bin" ] && path+=("$HOME/.local/bin")

# Predictable SSH authentication socket location.
# https://unix.stackexchange.com/a/76256
function () {
  local SOCK="/tmp/ssh-agent-$USER-screen"
  if [ -n "$SSH_CONNECTION" -a -n "$SSH_AUTH_SOCK" -a "$SSH_AUTH_SOCK" != "$SOCK" ]; then
    [ -L "$SOCK" ] && rm "$SOCK"
    ln -s "$SSH_AUTH_SOCK" "$SOCK"
    export SSH_AUTH_SOCK="$SOCK"
  fi
}

cmd_exists exa && alias l="exa -lbahg --git --time-style long-iso"
cmd_exists gls && alias ls="gls --color=auto"

cmd_exists tm && alias tm="exec tm"

# Use menu selection for autocompletion
zstyle ':completion:*' menu yes select

if cmd_exists brew; then
  function brup() {
    echo "### Running brew up…"
    brew up \
    && brew upgrade \
    && brew cask upgrade
  }
fi

function restart-gpg-agent() {
  # is there any gpg-agent running for other users?
  if [ "0" != "`ps aux | grep gpg-agent | grep -v /Users/$USER | grep -v grep | gwc -l`" ]; then
    echo "Need to kill gpg-agent of other users..."
    sudo killall gpg-agent
  fi

  echo "Killing agent"
  killall -9 gpg-agent
  gpgconf --kill gpg-agent
  echo "Launching agent"
  gpgconf --launch gpg-agent
}

function cht() {
  curl https://cheat.sh/awk
}

zinit light zsh-users/zsh-completions

zinit ice wait"0" atload"_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions

zinit ice wait
zinit light andrewferrier/fzf-z

zinit ice pick"async.zsh" src"pure.zsh"
zinit light sindresorhus/pure

zinit ice wait"0" atinit"zpcompinit; zpcdreplay; load_asdf_completions"
zinit light zdharma/fast-syntax-highlighting
