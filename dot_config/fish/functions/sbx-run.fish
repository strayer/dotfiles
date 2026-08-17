# Create a Docker Sandbox with my default kit set. Deliberately a separate
# command instead of shadowing sbx — call it explicitly when the defaults are
# wanted: `sbx-run claude`, extra args pass through to `sbx run`.
#
# Deliberately tracking `latest` for now (trusting Docker's publishing
# pipeline). To pin instead, set $tag to a date-SHA publishing tag from e.g.
# https://hub.docker.com/r/sbx/mise-kit/tags — all kits share the same tags.
#
# No default-kits setting exists in sbx yet — replace this function once
# https://github.com/docker/sbx-releases/issues/341 lands.
function sbx-run --wraps 'sbx run' --description 'sbx run with default kits (git-ssh-sign, github-ssh, mise, prek)'
    set -l tag latest
    sbx run \
        --kit docker.io/sbx/git-ssh-sign-kit:$tag \
        --kit docker.io/sbx/github-ssh-kit:$tag \
        --kit docker.io/sbx/mise-kit:$tag \
        --kit $HOME/.config/sbx-kits/prek \
        $argv
end
