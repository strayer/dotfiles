function restart-gpg-agent
  set -l current_user (whoami)

  # is there any gpg-agent running for other users?
  if test "0" != (ps aux | grep gpg-agent | grep -v /Users/$current_user | grep -v grep | gwc -l)
    echo "Need to kill gpg-agent of other users..."
    sudo killall gpg-agent
  end

  echo "Killing agent"
  killall -9 gpg-agent
  gpgconf --kill gpg-agent
  echo "Launching agent"
  gpgconf --launch gpg-agent
end
