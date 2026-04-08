function _sandbox-coding-agent
    set -l extra_args
    if command -q op
        set extra_args --enable=1password
    end
    if test -f "$HOME/.bin/secretive-ssh-keygen"
        set -a extra_args --add-dirs-ro="$HOME/.bin/secretive-ssh-keygen"
    end
    safe $extra_args $argv
end
