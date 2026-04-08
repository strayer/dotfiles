function safe
    set -l extra_args
    if command -q op
        set extra_args --enable=1password
    end
    safehouse --add-dirs-ro="$HOME/.global_gitignore" --add-dirs-ro="$HOME/.bin/secretive-ssh-keygen" $extra_args $argv
end
