# The ssh-agent-multiplexer socket (SSH_AUTH_SOCK on this machine) is
# read-only, so `step ssh login` can't add the daily certificate through it.
# Point step at the real launchd ssh-agent instead — the mux picks the cert
# up from there. Work machine only (gated in .chezmoiignore).
function step --wraps step --description 'step, with the launchd ssh-agent'
    SSH_AUTH_SOCK=(launchctl getenv SSH_AUTH_SOCK) command step $argv
end
