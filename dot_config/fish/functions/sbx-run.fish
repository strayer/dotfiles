# Create a Docker Sandbox with my default kit set. Deliberately a separate
# command instead of shadowing sbx — call it explicitly when the defaults are
# wanted: `sbx-run claude`, extra args pass through to `sbx run`.
#
# Kits load from the sbx-kits-contrib git repo, not the docker.io/sbx OCI
# artifacts: as of 2026-08-17 the OCI publishing pipeline is broken (latest
# tags carry an empty placeholder layer, older tags stale/empty content).
# Requires `github.com/docker/` in the kit.allowedSources setting. Tracking
# main for now; pin by replacing ref=main with ref=<commit-sha>.
#
# No default-kits setting exists in sbx yet — replace this function once
# https://github.com/docker/sbx-releases/issues/341 lands.
function sbx-run --wraps 'sbx run' --description 'sbx run with default kits (git-ssh-sign, github-ssh, mise, prek, claude-settings)'
    set -l repo 'git+https://github.com/docker/sbx-kits-contrib.git#ref=main&dir='
    sbx run \
        --kit "$repo"git-ssh-sign \
        --kit "$repo"github-ssh \
        --kit "$repo"mise \
        --kit $HOME/.config/sbx-kits/prek \
        --kit $HOME/.config/sbx-kits/claude-settings \
        $argv
end
