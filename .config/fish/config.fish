set -l host (string match -r "^[^.]+" $hostname)
set -l os (uname)

if type -q _pure_prompt
  # fix pure mute color for tokyonight
  # TODO: not sure this is actually correct?
  set pure_color_mute magenta
end

if test $hostname = "yobuko" -a $USER = "strayer"
  # Make sure Homebrew is in PATH
  eval (/opt/homebrew/bin/brew shellenv)

  # Use GPGs ssh-agent compatibility
  set -gx SSH_AUTH_SOCK "$HOME/.gnupg/S.gpg-agent.ssh"

  # Make sure gpg-agent is running so SSH can use its agent
  # set -l gpg_agent_pid (pgrep gpg-agent)
  # if test "$gpg_agent_pid" = ""
  #   echo "Starting gpg-agent"
  #   gpgconf --launch gpg-agent >/dev/null
  # end
end

# Make sure Homebrew is in PATH
if test -d /home/linuxbrew/.linuxbrew/bin
  fish_add_path /home/linuxbrew/.linuxbrew/bin
end
if test -d /home/linuxbrew/.linuxbrew/sbin
  fish_add_path /home/linuxbrew/.linuxbrew/sbin
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
fish_add_path "$HOME/.bin"
fish_add_path "$HOME/.local/bin"

# asdf
if test -d ~/.asdf
  source ~/.asdf/asdf.fish

  # Make sure asdf paths are in front
  fish_add_path -m "$HOME/.asdf/bin" "$HOME/.asdf/shims"

  # Check if the asdf completions are installed at the correct location
  if status --is-interactive; and test ! -e ~/.config/fish/completions/asdf.fish
    echo -e "\033[0;33mWARNING: asdf completions not found at ~/.config/fish/completions/asdf.fish\033[0m" >&2
  end

  set -gx RUBY_CONFIGURE_OPTS
  if test -d "/usr/local/opt/openssl@1.1"
    set -a RUBY_CONFIGURE_OPTS  "--with-openssl-dir=/usr/local/opt/openssl@1.1"
  end
  if test -d "/usr/local/opt/readline"
    set -a RUBY_CONFIGURE_OPTS  "--with-readline-dir=/usr/local/opt/readline"
  end

  if type -q aria2c
    set -gx RUBY_BUILD_HTTP_CLIENT aria2c
  end
end

# python poetry
fish_add_path "$HOME/.poetry/bin"

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

  if type -q zoxide
    zoxide init fish | source
  end
end
