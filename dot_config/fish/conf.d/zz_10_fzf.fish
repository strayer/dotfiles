# fzf.fish plugin configuration (https://github.com/PatrickF1/fzf.fish)
# Loaded after fzf.fish's own conf.d to override its defaults.
if status --is-interactive && type -q fzf_configure_bindings
  # Disable Ctrl+R — atuin handles history search (see Z_10_atuin.fish)
  fzf_configure_bindings --history=

  # Include hidden files (e.g. .github/) while still respecting .gitignore
  set fzf_fd_opts --hidden
  # Use lsd for directory previews in Search Directory
  set fzf_preview_dir_cmd lsd --all --color=always
  # Use delta for diff previews in Search Git Log and Search Git Status
  set fzf_diff_highlighter delta --paging=never --width=20
end
