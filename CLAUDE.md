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
tm <session>                         # tmux session manager (attach or create)
toggle-theme.sh [theme]              # System-wide theme switching with automation
install-dark-mode-notify.sh          # Setup automated theme switching via LaunchAgent
install-sbarlua.sh                   # Install SbarLua for SketchyBar configuration
secretive-ssh-keygen [args]          # SSH key generation using Secretive app
restart-gpg-agent.fish               # GPG agent management for multi-user conflicts
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
Sophisticated automated theme switching with cross-application coordination:
- **Supported themes**: tokyonight (day/storm/night), cyberdream variants
- **Applications**: bat, fish, kitty, alacritty, sketchybar, git-delta, aichat, neovim, wezterm
- **Implementation**: Symlinks managed by toggle-theme.sh with validation and logging
- **Automation**: LaunchAgent integration with dark-mode-notify binary for system detection
- **State management**: Theme persistence in `~/.cache/system-theme.txt`
- **Logging**: Comprehensive logging with rotation in `~/toggle-theme.log`

## Key Configuration Areas

### Development Environment
- **Runtime management**: mise configuration in `dot_config/mise/config.toml.tmpl`
- **Shell**: Fish with custom functions and theme integration
- **Terminal**: Multiple terminal configurations (kitty, alacritty, wezterm)
- **Git**: Environment-specific signing keys and configurations

### System Integration
- **SketchyBar**: Complete SbarLua configuration with modular architecture (`init.lua`, `bar.lua`, `default.lua`, items/*). Includes aerospace integration, custom items (battery, network, clock, volume, meal planning), and theme coordination. Coding agents can use the deepwiki mcp to retrieve information about [SketchyBar](https://deepwiki.com/FelixKratz/SketchyBar) and [SbarLua](https://deepwiki.com/FelixKratz/SbarLua).
- **Package management**: Comprehensive Brewfile (260+ work packages, 290+ home packages) with custom taps, MAS automation, and environment-specific tool sets
- **Karabiner**: Custom keyboard modifications in `private_karabiner/`
- **LaunchAgent automation**: Automated theme switching and system integration services

### Security & Privacy
- **GPG configuration**: Agent settings with multi-user conflict resolution and smart card support
- **SSH**: Separate configurations for different services with Secretive app integration (home machine)
- **Authentication**: SSH agent socket management for tmux/screen sessions
- **Private files**: Use `private_` prefix for sensitive configurations (Karabiner, SSH keys)

## Working with Templates

When editing `.tmpl` files, common patterns include:
- `{{ if eq .chezmoi.hostname "CO-MBP-KC9KQV64V3" }}` - Work-specific configuration
- `{{ .email }}` - User-provided email address
- `{{ .atuin_sync_server }}` - Atuin sync server URL
- `{{ .vertex_ai.base_url }}` - Claude Code Vertex AI configuration
- `{{ env "HOME" }}` - Environment variable access
- `{{- if eq .chezmoi.hostname "work" }}` - Conditional blocks with whitespace control

Always test template changes with `chezmoi diff` before applying to avoid syntax errors in generated configurations.

## Automation & Integration

### LaunchAgent Setup
```bash
install-dark-mode-notify.sh         # Install automated theme switching
launchctl load ~/Library/LaunchAgents/com.user.darkmode.plist
```

### Development Workflows
- **Environment bootstrapping**: Use `chezmoi init` with template variable prompts
- **Theme automation**: LaunchAgent responds to system dark mode changes automatically
- **GPG agent conflicts**: Use `restart-gpg-agent.fish` when multiple users conflict
- **SSH key management**: Use `secretive-ssh-keygen` for Secretive app integration

## Conventional Commit Guidelines

- Use conventional commit message format for all commits
- Common scopes based on repository files:
  - `Brewfile`: Package management updates
  - `fish`: Fish shell configurations
  - `kitty`, `alacritty`, `wezterm`, `ghostty`: Terminal emulator configs
  - `sketchybar`: Status bar configuration
  - `mise`: Runtime version management
  - `git`, `gitconfig`: Git configuration
  - `claude`: Claude Code settings
  - `karabiner`: Keyboard customization
  - `terminal`: Cross-terminal features
  - `atuin`: Command history settings
  - `chezmoi`: Dotfiles management
  - `bin`: Custom scripts in ~/.bin/
- Type usage patterns:
  - `feat`: New features or additions (most common)
  - `fix`: Bug fixes or corrections
  - `chore`: Maintenance, updates without functional changes
  - `refactor`: Code restructuring without behavior changes
  - `docs`: Documentation updates
  - `style`: Formatting, cosmetic changes
  - `perf`: Performance improvements
  - `test`: Testing-related changes
  - `ci`: CI/CD configurations
- Format: `<type>(<scope>): <description>`
  - Scope is optional for general changes (e.g., `chore: add CLAUDE.md`)
  - Use present tense, imperative mood
  - Keep descriptions concise and specific