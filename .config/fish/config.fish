set -l host (hostname | cut -d . -f 1)
set -l user (whoami)

set -g fish_prompt_pwd_dir_length 2
set -g theme_nerd_fonts yes
set -g theme_color_scheme gruvbox
set -g theme_display_k8s_context no
function fish_right_prompt; end

# fish fzf
set -g FZF_FIND_FILE_COMMAND 'rg --files --no-ignore --hidden --follow -g "!{.git,node_modules}/*" 2> /dev/null'
set -g FZF_TMUX 1

# Android
if test -d $HOME/Library/Android/sdk
  set -gx ANDROID_HOME "$HOME/Library/Android/sdk"
  set -gx PATH "$ANDROID_HOME/platform-tools" $PATH
  set -gx PATH "$ANDROID_HOME/tools" $PATH
end

if test $host = "wolf359" -a $user = "strayer"
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

if test -e "$HOME/.homebrew-github-token"
  set -gx HOMEBREW_GITHUB_API_TOKEN (cat $HOME/.homebrew-github-token)
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
    set -gx EDITOR nvim
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
    ls -lav --time-style=long-iso $argv
  end

  function du
    if type -q gdu
      gdu -k $argv
    else
      command du -k $argv
    end
  end

  if type -q brew
    function brup
      brew up
      brew upgrade
      brew cleanup
      brew cask cleanup
      brew cask outdated
    end
  end

  if type -q mpv
    function mpv-vp9
      mpv --ytdl-format="bestvideo[ext=webm]+bestaudio" $argv
    end
  end

  if type -q direnv
    eval (direnv hook fish)
  end
end
