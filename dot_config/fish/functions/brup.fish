function brup
    echo "### Running brew up…"
    brew up; or return
    brew upgrade; or return
    test (uname -s) = "Darwin"; and brew upgrade --cask
    if test -e $HOME/.bin/outdated-packages.sh
        echo "Pruning outdated-packages cache"
        $HOME/.bin/outdated-packages.sh prune
    end
    brew cleanup
end
