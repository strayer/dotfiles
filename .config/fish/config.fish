set -l host (hostname | cut -d . -f 1)
set -l user (whoami)

set -g fish_prompt_pwd_dir_length 2
set -g theme_nerd_fonts yes
set -g theme_color_scheme gruvbox
set -g theme_display_k8s_context no
set -g theme_display_ruby no
function fish_right_prompt; end

# fish fzf
set -g FZF_FIND_FILE_COMMAND 'rg --files --no-ignore --hidden --follow -g "!{.git,node_modules}/*" 2> /dev/null'
set -g FZF_LEGACY_KEYBINDINGS 0
set -g FZF_TMUX 1
set -x FZF_DEFAULT_OPTS "--tiebreak=index --bind=ctrl-r:toggle-sort +m"

# Android
if test -d $HOME/Library/Android/sdk
  set -gx ANDROID_HOME "$HOME/Library/Android/sdk"
  set -gx PATH "$ANDROID_HOME/platform-tools" $PATH
  set -gx PATH "$ANDROID_HOME/tools" $PATH
end

if test $host = "wolf359" -a \( $user = "strayer" -o $user = "work" \)
  # Use GPGs ssh-agent compatibility
  set -gx SSH_AUTH_SOCK "$HOME/.gnupg/S.gpg-agent.ssh"

  # Make sure gpg-agent is running so SSH can use its agent
  gpgconf --launch gpg-agent >/dev/null

  # Add /usr/local/sbin to path if it exists
  if test -d "/usr/local/sbin"
    set -gx PATH /usr/local/sbin $PATH
  end
end

# Local software & scripts
if test -d "$HOME/.bin"
  set -gx PATH "$HOME/.bin" $PATH
end

# Rust stuff
if test -d "$HOME/.cargo/bin"
  set -gx PATH "$HOME/.cargo/bin" $PATH
end

# asdf
if test -d ~/.asdf
  source ~/.asdf/asdf.fish
  if test ! -e ~/.config/fish/completions/asdf.fish
    ln -s ~/.asdf/completions/asdf.fish ~/.config/fish/completions/asdf.fish
  end
end

if type -q brew
  if test -e "$HOME/.homebrew-github-token"
    set -gx HOMEBREW_GITHUB_API_TOKEN (cat $HOME/.homebrew-github-token)
  end

  set -gx HOMEBREW_NO_ANALYTICS 1
  set -gx HOMEBREW_NO_AUTO_UPDATE 1
end

# Spacefish theme
set SPACEFISH_BATTERY_THRESHOLD 80
if test $host = "wolf359" -a $user = "strayer"
  set SPACEFISH_PROMPT_ORDER time user dir host git exec_time line_sep battery jobs exit_code char
else if test $host = "wolf359" -a $user = "work"
  set SPACEFISH_PROMPT_ORDER time user dir host git aws kubecontext exec_time line_sep battery jobs exit_code char
end

# Interactive shell stuff
if status --is-interactive
  # Source correct dircolor configuration for coreutils
  if type -q gdircolors; and test -e "$HOME/Documents/Entwicklung/_extern/dircolors-solarized/dircolors.ansi-universal"
    bass (gdircolors $HOME/Documents/Entwicklung/_extern/dircolors-solarized/dircolors.ansi-universal )
  end

  # Set correct colors for bsd ls
  set -gx LSCOLORS gxfxbEaEBxxEhEhBaDaCaD

  # Set editor
  if type -q nvim
    if test -e "/home/linuxbrew/.linuxbrew/bin/nvim"
      set -gx EDITOR /home/linuxbrew/.linuxbrew/bin/nvim
    else
      set -gx EDITOR nvim
    end
  else if type -q vim
    set -gx EDITOR vim
  end

  function ls
    if type -q gls
      gls --color=auto $argv
    else
      command ls $argv
    end
  end

  function l
    exa -lbah --git --time-style long-iso $argv
  end

  function du
    if type -q gdu
      gdu -k $argv
    else
      command du -k $argv
    end
  end

  function tm
    exec tm
  end

  if type -q brew
    function brup
      echo "### Running brew up…"
      brew up
      and brew upgrade
      and brew cask upgrade
      and brew cleanup
    end
  end

  if type -q mpv
    function mpv
      if ioreg -rc "AppleSmartBattery" | grep -q "\"ExternalConnected\" = Yes"
        printf "Prefering vp9 (external power source connected)\n"
        command mpv --profile=with-vp9 $argv
      else
        command mpv $argv
      end
    end
  end

  if type -q direnv
    eval (direnv hook fish)
  end

  if type -q pyenv
    source (pyenv init - | psub)
  end

  if type -q pyenv-virtualenv
    source (pyenv virtualenv-init - | psub)
  end

  if test -e $HOME/.kube/config
    function copy-k8s-token
      gpg -d $HOME/.kube/token.asc | jq .status.token -r - | pbcopy
    end
  end
  
  if test -e $HOME/.emacs.d/bin/doom
    alias doom=$HOME/.emacs.d/bin/doom
  end

  if test -e /usr/local/Homebrew/Library/Taps/homebrew/homebrew-command-not-found/
    brew command command-not-found-init > /dev/null 2>&1; and . (brew command-not-found-init)
  end
end
