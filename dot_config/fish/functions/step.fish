# The ssh-agent-multiplexer socket (SSH_AUTH_SOCK on this machine) is
# read-only, so `step ssh login` can't add the daily certificate through it.
# Point step at the real launchd ssh-agent instead — the mux picks the cert
# up from there. Work machine only (gated in .chezmoiignore).
#
# herdr (0.9.1+) moves its server into launchd's per-user Background context
# so panes survive logout. There `launchctl getenv` doesn't see the Aqua
# session's SSH_AUTH_SOCK, so read the socket from the agent's GUI job.
function step --wraps step --description 'step, with the launchd ssh-agent'
    if set -q HERDR_ENV
        set -f sock (launchctl print gui/(id -u)/com.openssh.ssh-agent 2>/dev/null \
            | string match -rg 'SSH_AUTH_SOCK => (\S+)')[1]
    else
        set -f sock (launchctl getenv SSH_AUTH_SOCK)
    end
    if test -z "$sock"
        echo "step: launchd ssh-agent socket not found" >&2
        return 1
    end
    SSH_AUTH_SOCK=$sock command step $argv
end
