# 🔧 configure-claude

A simple, interactive CLI tool for managing Claude Code settings across different LLM providers.

## ✨ Features

- **Multi-Provider Support**: Seamlessly switch between Google Vertex AI and AWS Bedrock
- **Smart Configuration**: Preserves custom settings when switching providers
- **Caching**: Remembers your previous configurations for quick switching
- **Interactive Prompts**: User-friendly CLI with rich formatting
- **Multiple Auth Methods**: Supports various authentication strategies for each provider

## 🚀 Quick Start

```bash
# Run the configuration wizard
configure-claude
```

The tool will guide you through:
1. Selecting your LLM provider (Vertex AI or Bedrock)
2. Choosing an authentication method
3. Entering required credentials and settings

## 🔑 Supported Providers

### Google Vertex AI

**Authentication Methods:**
- **LiteLLM** (via proxy): Requires GCP Project ID and LiteLLM base URL
- **Direct**: Direct Vertex AI authentication with GCP Project ID

**Regions:**
- Primary: `europe-west1` (Claude 4.0 Sonnet, 4.5 Sonnet, 4.5 Haiku)
- Global: `global` (Cloud ML)

### AWS Bedrock

**Authentication Methods:**
- **API Key**: Uses custom API key helper script
- **AWS Profile**: Authenticates using AWS CLI profile

**Regions:**
- Primary: `eu-central-1` (Claude 4.5 Sonnet)
- Secondary: `us-east-1` (Claude 3.5 Haiku)

## 📋 How It Works

1. **Reads** your current `~/.claude/settings.json` configuration
2. **Detects** active provider and authentication method
3. **Prompts** for new provider/auth selection
4. **Merges** base settings with provider-specific configurations
5. **Preserves** any custom settings you've added
6. **Writes** the new configuration to `~/.claude/settings.json`
7. **Caches** your inputs for future runs

## 🔒 Base Settings

The tool maintains consistent settings across all providers. See [`base-settings.json`](base-settings.json) for details.

## 📝 Cache Location

Configuration cache is stored at platform-specific locations:

- **macOS**: `~/Library/Caches/configure-claude/cache.json`
- **Linux**: `~/.cache/configure-claude/cache.json`

This cache stores your previous inputs for each provider/auth combination, making it easy to switch between configurations without re-entering values.
