if test -e /opt/homebrew/bin/brew
  # Make sure Homebrew is in PATH
  eval (/opt/homebrew/bin/brew shellenv)
end

# Make sure Homebrew is in PATH
if test -d /home/linuxbrew/.linuxbrew/bin
  fish_add_path /home/linuxbrew/.linuxbrew/bin
end
if test -d /home/linuxbrew/.linuxbrew/sbin
  fish_add_path /home/linuxbrew/.linuxbrew/sbin
end
