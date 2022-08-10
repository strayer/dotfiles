function configure-light-theme
  # Github
  yes | fish_config theme save 'Ayu Light'
  kitty +kitten themes --reload-in=all github

  # Dayfox
  # cat $HOME/.local/share/nvim/site/pack/packer/start/nightfox.nvim/extra/dayfox/nightfox_fish.fish | sed 's/set -g/set -U/' | source
  # kitty +kitten themes --reload-in=all dayfox

  # Tokyo Night Day
  # cat $HOME/.local/share/nvim/site/pack/packer/start/tokyonight.nvim/extras/fish_tokyonight_day.fish | sed 's/set -g/set -U/' | source
  # kitty +kitten themes --reload-in=all "Tokyo Night Day"

  set -Ux BAT_THEME GitHub
  set -Ux LS_COLORS (vivid generate one-light)
  set -Ux TERMINAL_THEME light
end

