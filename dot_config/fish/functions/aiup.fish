function aiup --description "Update Homebrew and upgrade coding agent casks (claude-code, codex)"
    echo "### Running brew update…"
    brew update; or return
    echo "### Upgrading claude-code@latest and codex…"
    brew upgrade -y --cask claude-code@latest codex
end
