source ~/.zinit/bin/zinit.zsh

function cmd_exists() {
  (( $+commands[$1] ))
}

# force PATH to have unique values
typeset -U path

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt inc_append_history     # add commands to HISTFILE in order of execution
setopt share_history          # share command history data

# Color for zsh-autosuggestions
# palenight
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#68709B"

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
  export MANPAGER='nvim +Man!'
  export MANWIDTH=999
elif cmd_exists vim; then
  export EDITOR=vim
fi

# force emacs key bindings
set -o emacs

autoload -U edit-command-line
zle -N edit-command-line
bindkey '^xe' edit-command-line
bindkey '^x^e' edit-command-line

# Local software and scripts
if [ -d "$HOME/.bin" ]; then
  path=("$HOME/.bin" $path)
fi

# asdf
ASDF_DIR="$HOME/.asdf"
if [ -d "$ASDF_DIR" ]; then
  . $ASDF_DIR/asdf.sh
  fpath=(${ASDF_DIR}/completions $fpath)

  # Configure ruby-build to use Homebrew openssl and readline
  typeset -UT RUBY_CONFIGURE_OPTS ruby_configure_opts ' '
  if [ -d "/usr/local/opt/openssl@1.1" ]; then
    ruby_configure_opts+=('--with-openssl-dir=/usr/local/opt/openssl@1.1')
  fi
  if [ -d "/usr/local/opt/readline" ]; then
    ruby_configure_opts+=('--with-readline-dir=/usr/local/opt/readline')
  fi
  export RUBY_CONFIGURE_OPTS

  if cmd_exists aria2c; then
    export RUBY_BUILD_HTTP_CLIENT="aria2c"
  fi
fi

# bundle
if cmd_exists bundle; then
  alias be="bundle exec"
fi

# fzf
if [ -f ~/.fzf.zsh ]; then
  export FZF_TMUX=1
  source ~/.fzf.zsh

  # Enable popup functionality for fzf
  export FZF_TMUX_OPTS="-p"
fi
if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
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

# rust
if [ -d "$HOME/.cargo/bin" ]; then
  path=("$HOME/.cargo/bin" $path)
fi

# Aliases for Git
if cmd_exists git; then
  alias gnb="git checkout -b strayer/"
  alias gs="git stash"

  gnbm() {
    branch="strayer/$1"
    # sed removes whitespace to fix macOS wc output with tabs
    if [ "$(git branch --list $branch | wc -l | sed 's/^ *//')" != "0" ]; then
      echo "Branch $branch already exists"
      return
    fi
    git fetch
    git checkout --no-track -b $branch origin/master
  }
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

# Aliases for Docker
if cmd_exists docker; then
  alias compose="docker compose"
fi

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
    && brew upgrade --cask
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

# Disable eternal terminal telemetry
export ET_NO_TELEMETRY=1

# Show the current working directory in the terminal window titlebar
function set-title-precmd () { printf "\033]2;${PWD/$HOME/~}\007" }
function set-title-preexec() { printf "\e]2;%s\a" "$1" }
autoload -Uz add-zsh-hook
add-zsh-hook precmd set-title-precmd
add-zsh-hook preexec set-title-preexec

# z.lua
export _ZL_MATCH_MODE=1
alias zz='z -c'      # restrict matches to subdirs of $PWD
alias zi='z -i'      # cd with interactive selection
alias zf='z -I'      # use fzf to select in multiple matches
alias zb='z -b'      # quickly cd to the parent directory
FZ_HISTORY_CD_CMD="_zlua" # integrate with fz

# fzf-tab
zstyle ":completion:*:git-checkout:*" sort false
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'exa -1 --color=always $realpath'
# Enable popup functionality, requires tmux > 3.2
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

zinit light zsh-users/zsh-completions

zinit ice wait"0" atload"_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions

# gcloud
if [[ -d /usr/local/Caskroom/google-cloud-sdk/ ]]; then
  source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
fi
# unmaintained/archived
# zinit ice wait
# zinit light andrewferrier/fzf-z

zinit ice wait
zinit light skywind3000/z.lua

zinit ice wait
zinit light changyuheng/fz

# zinit ice compile"(pure|async).zsh" pick"async.zsh" src"pure.zsh"
# zinit light sindresorhus/pure

zinit ice depth=1; zinit light romkatv/powerlevel10k

# https://github.com/zdharma/zinit/issues/260#issuecomment-618274313
zinit light-mode lucid wait has"kubectl" for \
  id-as"kubectl_completion" \
  as"completion" \
  atclone"kubectl completion zsh > _kubectl" \
  atpull"%atclone" \
  run-atpull \
    zdharma/null

zinit light-mode lucid wait has"rustup" for \
  id-as"rustup_completion" \
  as"completion" \
  atclone"rustup completions zsh > _rustup" \
  atpull"%atclone" \
  run-atpull \
    zdharma/null

zinit light-mode lucid wait has"poetry" for \
  id-as"poetry_completion" \
  as"completion" \
  atclone"poetry completions zsh > _poetry" \
  atpull"%atclone" \
  run-atpull \
    zdharma/null

zplugin ice blockf if'[[ "$(uname)" == "Darwin" &&  -d /usr/local/Caskroom/google-cloud-sdk/ ]]'
zplugin snippet /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc

zinit light Aloxaf/fzf-tab

zinit ice wait"0" atinit"zpcompinit; zpcdreplay"
zinit light zdharma/fast-syntax-highlighting

# eval "$(starship init zsh)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

alias luamake=/Users/strayer/.config/nvim/lua-language-server/3rd/luamake/luamake
