function brup
    argparse caffeinate -- $argv
    or return

    if set -q _flag_caffeinate
        echo "### Wrapping brup with caffeinate -dims…"
        caffeinate -dims fish -c brup
        return
    end

    echo "### Running brew up…"
    brew up; or return
    brew upgrade -y --greedy-latest; or return
    brew cleanup
end
