function configure-theme --argument mode_setting
  set -l mode "light" # default value
  if test -z $mode_setting
    defaults read -g AppleInterfaceStyle 2>/dev/null >/dev/null
    if test $status -eq 0
      set mode "dark"
    end
  else
    switch $mode_setting
      case light
        osascript -l JavaScript -e "Application('System Events').appearancePreferences.darkMode = false" >/dev/null
        set mode "light"
      case dark
        osascript -l JavaScript -e "Application('System Events').appearancePreferences.darkMode = true" >/dev/null
        set mode "dark"
    end
  end

  switch $mode
    case dark
      configure-dark-theme
    case light
      configure-light-theme
  end
end

