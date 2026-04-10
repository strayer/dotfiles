function _sb-coding-agent --description "Shared sandbox setup for coding agents"
    set -l extra_args \
        --add-dirs-ro="$HOME/.global_gitignore" \
        --enable=clipboard

    # Allow 1Password CLI access
    if command -q op
        set -a extra_args --enable=1password
    end

    # Allow Secretive SSH key generation
    if test -f "$HOME/.bin/secretive-ssh-keygen"
        set -a extra_args --add-dirs-ro="$HOME/.bin/secretive-ssh-keygen"
    end

    safehouse $extra_args $argv
end
