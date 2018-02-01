set -l host (hostname | cut -d . -f 1)
set -l user (whoami)

set -g fish_prompt_pwd_dir_length 3
set -g theme_nerd_fonts yes

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

if test -e "$HOME/.homebrew-github-token"
  set -gx HOMEBREW_GITHUB_API_TOKEN (cat $HOME/.homebrew-github-token)
end

# Interactive shell stuff
if status --is-interactive
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
