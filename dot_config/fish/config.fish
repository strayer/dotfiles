set -l host (string match -r "^[^.]+" $hostname)
set -l os (uname)

if type -q _pure_prompt
  # fix pure mute color for tokyonight
  # TODO: not sure this is actually correct?
  set pure_color_mute magenta
end

if test $hostname = "yobuko" -a $USER = "strayer"
  if test -e "$HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh"
    set -gx SSH_AUTH_SOCK $HOME/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
  end
end

# Android
if test -d $HOME/Library/Android/sdk
  set -gx ANDROID_HOME "$HOME/Library/Android/sdk"
  fish_add_path "$ANDROID_HOME/platform-tools" "$ANDROID_HOME/tools"
end

# Configure default editor
if type -q nvim
  set -gx EDITOR nvim
  set -gx MANPAGER 'nvim +Man!'
  set -gx MANWIDTH 999
else if type -q vim
  set -gx EDITOR vim
end

# Local software & scripts
fish_add_path "$HOME/.local/bin"

# python poetry
fish_add_path "$HOME/.poetry/bin"

# more up to date cURL
fish_add_path /opt/homebrew/opt/curl/bin

# Homebrew
if type -q brew
  if test -e "$HOME/.homebrew-github-token"
    read -gx HOMEBREW_GITHUB_API_TOKEN < $HOME/.homebrew-github-token
  end

  set -gx HOMEBREW_NO_ANALYTICS 1
  set -gx HOMEBREW_NO_AUTO_UPDATE 1
  set -gx HOMEBREW_INSTALL_CLEANUP 1
end

# google-cloud-sdk
if type -q gcloud && test -e /usr/local/bin/python3
  set -gx CLOUDSDK_PYTHON /usr/local/bin/python3
end

# Rust
fish_add_path "$HOME/.cargo/bin"

# Disable cowsay for ansible
if type -q cowsay -a -q ansible
  set -gx ANSIBLE_NOCOWS 1
end

# Predictable SSH authentication socket location.
# https://unix.stackexchange.com/a/76256
set SOCK "/tmp/ssh-agent-$USER-screen"
if set -q SSH_CONNECTION; and set -q SSH_AUTH_SOCK; and test $SSH_AUTH_SOCK != $SOCK
  test -L $SOCK && rm $SOCK

  ln -s $SSH_AUTH_SOCK $SOCK
  set -gx SSH_AUTH_SOCK $SOCK
end

# Disable eternal terminal telemetry
set -gx ET_NO_TELEMETRY 1

if status --is-interactive
  function ls
    if type -q gls
      gls --color=auto $argv
    else
      command ls $argv
    end
  end

  if type -q exa
    function l
      exa -lbahg --git --time-style long-iso $argv
    end
  end

  if type -q lsd
    function l
      lsd -lah --date "+%F %T" $argv
    end
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
      echo "### Running brew up…"
      brew up; or return
      brew upgrade; or return
      test "$os" = "Darwin"; and brew upgrade --cask
      brew cleanup
    end
  end

  # if type -q kitty
  #   kitty + complete setup fish | source
  # end

  if type -q docker
    abbr --add --global compose docker compose
    abbr --add --global dr docker run
    abbr --add --global de docker exec

    if type -q op
      abbr --add --global opcompose op run --no-masking -- docker compose
    end
  end

  if type -q bundle
    abbr --add --global be bundle exec

    if type -q docker
      function cbe
        docker compose exec "$argv[1]" bundle exec $argv[2..-1]
      end
    end
  end

  if type -q git
    abbr --add --global g git
  end

  if type -q terraform
    abbr --add --global tf terraform
  end

  if type -q zoxide
    zoxide init fish | source
  end

  if type -q starship
    starship init fish | source
  end

  if type -q gh
    abbr --add --global ai gh copilot explain
    abbr --add --global aie gh copilot suggest
  end
end

# Added by OrbStack: command-line tools and integration
if test -e "$HOME/.orbstack/shell/init2.fish"
  source ~/.orbstack/shell/init2.fish 2>/dev/null || :
end

# Added by LM Studio; command-line tools
if test -e "$HOME/.cache/lm-studio/bin"
  fish_add_path "$HOME/.cache/lm-studio/bin"
end

# Add ~/.bin last to have it as the highest priority in PATH
fish_add_path --move --prepend "$HOME/.bin"
