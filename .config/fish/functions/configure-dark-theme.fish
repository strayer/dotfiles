function configure-dark-theme
  yes | fish_config theme save 'tokyonight_storm'
  command -v kitty && kitty +kitten themes --reload-in=all "Tokyo Night Storm"

  set -Ux BAT_THEME OneHalfDark
  command -v vivid && set -Ux LS_COLORS (vivid generate snazzy)
  set -Ux TERMINAL_THEME dark
end

