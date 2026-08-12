# WSL never runs pam_env, so the XDG_DATA_DIRS entry in /etc/environment is
# ignored there and fish never sees Linuxbrew's vendor dirs. Wire them up
# directly instead (brew shellenv itself already ran in 00_homebrew.fish).
#
# fish computed its vendor dirs from XDG_DATA_DIRS before this file ran, so
# exporting the variable alone is too late for THIS shell — extend the paths
# directly and source vendor snippets by hand. Because XDG_DATA_DIRS is
# exported, nested fish (tmux, fish inside fish) picks the vendor dirs up
# natively at startup and the `contains` guard makes this a no-op. Same on
# hosts where /etc/environment does work (SSH logins on the headless fleet)
# and on machines without Linuxbrew.
set -l brew_share /home/linuxbrew/.linuxbrew/share

if test -x /home/linuxbrew/.linuxbrew/bin/brew
    if not contains $brew_share/fish/vendor_completions.d $fish_complete_path
        set -gx XDG_DATA_DIRS "$brew_share:/usr/local/share:/usr/share"
        set -a fish_complete_path $brew_share/fish/vendor_completions.d
        set -a fish_function_path $brew_share/fish/vendor_functions.d
        for f in $brew_share/fish/vendor_conf.d/*.fish
            source $f
        end
    end
end
