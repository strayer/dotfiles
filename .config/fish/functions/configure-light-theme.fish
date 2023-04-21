function configure-light-theme
  # Github
  yes | fish_config theme save 'ayu Light'
  command -v kitty && kitty +kitten themes --reload-in=all github

  # Tokyo Night Day
  # yes | fish_config theme save 'tokyonight_day'
  # kitty +kitten themes --reload-in=all "Tokyo Night Day"

  set -Ux BAT_THEME GitHub
  command -v vidid && set -Ux LS_COLORS (vivid generate one-light)
  set -Ux TERMINAL_THEME light
end

