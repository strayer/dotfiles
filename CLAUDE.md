# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a chezmoi dotfiles repository that manages configuration files across multiple environments (work and home machines). The repository uses Go templating for environment-specific configurations and supports automated theme switching across all applications.

## Chezmoi File Naming Conventions

- `dot_` prefix: Files/directories that become `.filename` in the home directory
- `executable_` prefix: Files that should be executable after deployment  
- `symlink_` prefix: Files that should be symlinked rather than copied
- `private_` prefix: Files with restricted permissions
- `.tmpl` suffix: Template files using Go templating with chezmoi variables

## Common Commands

### Chezmoi Management
```bash
chezmoi apply          # Apply changes to home directory
chezmoi diff           # Show pending changes before applying
chezmoi edit <file>    # Edit files in chezmoi source directory
chezmoi cd             # Navigate to chezmoi source directory (/Users/grunewaldtsv/.local/share/chezmoi)
chezmoi update         # Pull and apply changes from remote repository
```

### Custom Scripts (in ~/.bin/)
```bash
tm <session>           # tmux session manager
toggle-theme.sh        # System-wide theme switching (tokyonight variants, cyberdream)
```

## Architecture & Environment Detection

### Hostname-Based Configuration
- **Work machine**: `CO-MBP-KC9KQV64V3` - Different Git signing, package sets, restricted configurations
- **Home machine**: `yobuko` - Full package access, personal configurations
- Templates use `{{ .chezmoi.hostname }}` for conditional logic

### Template Variables
The repository prompts for sensitive configuration during initial setup:
- Email address (Git configuration)
- Atuin sync server URL
- Claude Code Vertex AI settings (base URL, project ID, location)

### Theme Management System
Centralized theme switching affects multiple applications simultaneously:
- **Supported themes**: tokyonight (day/storm/night), cyberdream variants
- **Applications**: bat, fish, kitty, alacritty, sketchybar
- **Implementation**: Symlinks managed by toggle-theme.sh script
- **Auto-detection**: Responds to system dark mode changes

## Key Configuration Areas

### Development Environment
- **Runtime management**: mise configuration in `dot_config/mise/config.toml.tmpl`
- **Shell**: Fish with custom functions and theme integration
- **Terminal**: Multiple terminal configurations (kitty, alacritty, wezterm)
- **Git**: Environment-specific signing keys and configurations

### System Integration
- **SketchyBar**: Custom status bar with aerospace window manager integration
- **Package management**: Comprehensive Brewfile with environment-specific sections
- **Karabiner**: Custom keyboard modifications in `private_karabiner/`

### Security & Privacy
- **GPG configuration**: Agent settings and smart card support
- **SSH**: Separate configurations for different services
- **Private files**: Use `private_` prefix for sensitive configurations

## Working with Templates

When editing `.tmpl` files, common patterns include:
- `{{ if eq .chezmoi.hostname "CO-MBP-KC9KQV64V3" }}` - Work-specific configuration
- `{{ .email }}` - User-provided email address
- `{{ .atuin_sync_server }}` - Atuin sync server URL
- `{{ .vertex_ai.base_url }}` - Claude Code Vertex AI configuration

Always test template changes with `chezmoi diff` before applying to avoid syntax errors in generated configurations.