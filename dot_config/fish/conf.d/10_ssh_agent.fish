# Point SSH_AUTH_SOCK at the systemd user ssh-agent (headless Linux boxes;
# see dot_config/systemd/user/ssh-agent.service). No-op elsewhere: the socket
# only exists where that unit runs. config.fish runs after conf.d and still
# overrides this with Secretive on yobuko.
if test -n "$XDG_RUNTIME_DIR"; and test -S "$XDG_RUNTIME_DIR/ssh-agent.socket"
  set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent.socket"
end
