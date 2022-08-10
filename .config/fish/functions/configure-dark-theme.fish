function configure-dark-theme
  set -l nightfox $HOME/.local/share/nvim/site/pack/packer/start/nightfox.nvim/extra/nightfox/nightfox_fish.fish
  set -l tokyonight $HOME/.local/share/nvim/site/pack/packer/start/tokyonight.nvim/extras/fish_tokyonight_storm.fish

  # cat $nightfox | sed 's/set -g/set -U/' | source
  # kitty +kitten themes --reload-in=all nightfox

  cat $tokyonight | sed 's/set -g/set -U/' | source
  kitty +kitten themes --reload-in=all "Tokyo Night Storm"

  set -Ux BAT_THEME OneHalfDark
  set -Ux LS_COLORS (vivid generate snazzy)
  set -Ux TERMINAL_THEME dark
end

