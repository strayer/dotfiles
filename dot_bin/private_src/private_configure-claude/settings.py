"""Settings file operations for ~/.claude/settings.json"""

import json
from pathlib import Path

from config import PROVIDER_CONFIGS
from custom_types import Provider


def load_base_settings() -> dict:
    """Load base settings from base-settings.json"""
    base_path = Path(__file__).parent / "base-settings.json"
    with base_path.open() as f:
        return json.load(f)


def build_settings(
    provider: Provider,
    auth_method: str,
    variables: dict,
) -> dict:
    """
    Build final settings by merging base settings with provider-specific configs.

    Args:
        provider: "vertex" or "bedrock"
        auth_method: Auth method for the provider
        variables: User-provided variables (project_id, base_url, etc.)

    Returns:
        Complete settings dict ready to write to ~/.claude/settings.json
    """
    settings = load_base_settings()

    # Add provider-specific env vars
    provider_config = PROVIDER_CONFIGS[provider]
    settings["env"].update(provider_config["common_env"])
    settings["env"].update(provider_config["auth"][auth_method]["env"])

    # Add dynamic variables specific to each provider
    if provider == "vertex":
        settings["env"]["ANTHROPIC_VERTEX_PROJECT_ID"] = variables["project_id"]
        if auth_method == "litellm":
            settings["env"]["ANTHROPIC_VERTEX_BASE_URL"] = variables["base_url"]
    elif provider == "bedrock":
        if auth_method == "aws_profile":
            settings["env"]["AWS_PROFILE"] = variables["aws_profile"]

    # Add apiKeyHelper if configured
    api_key_helper = provider_config["auth"][auth_method]["api_key_helper"]
    if api_key_helper:
        settings["apiKeyHelper"] = api_key_helper

    return settings


def read_settings(
    settings_path: Path | None = None,
) -> dict | None:
    """Read current settings.json, return None if doesn't exist."""
    if settings_path is None:
        settings_path = Path.home() / ".claude" / "settings.json"

    if not settings_path.exists():
        return None

    with settings_path.open() as f:
        return json.load(f)


def write_settings(settings: dict, settings_path: Path | None = None) -> None:
    """Write settings to file with pretty formatting."""
    if settings_path is None:
        settings_path = Path.home() / ".claude" / "settings.json"

    settings_path.parent.mkdir(parents=True, exist_ok=True)

    with settings_path.open("w") as f:
        json.dump(settings, f, indent=2)
        f.write("\n")  # Trailing newline


def detect_provider(settings: dict | None) -> Provider | None:
    """Detect current provider from settings. Returns 'vertex', 'bedrock', or None."""
    if not settings:
        return None

    env = settings.get("env", {})

    if "CLAUDE_CODE_USE_VERTEX" in env:
        return "vertex"
    if "CLAUDE_CODE_USE_BEDROCK" in env:
        return "bedrock"

    return None


def detect_auth_method(
    settings: dict | None, provider: Provider
) -> str | None:
    """
    Detect the auth method for a given provider from current settings.

    Returns:
        - For vertex: "litellm" or "direct"
        - For bedrock: "api_key" or "aws_profile"
        - None if cannot be determined
    """
    if not settings:
        return None

    env = settings.get("env", {})

    if provider == "vertex":
        if "CLAUDE_CODE_SKIP_VERTEX_AUTH" in env:
            return "litellm"
        elif "CLAUDE_CODE_USE_VERTEX" in env:
            return "direct"
    elif provider == "bedrock":
        if "CLAUDE_CODE_SKIP_BEDROCK_AUTH" in env:
            return "api_key"
        elif "AWS_PROFILE" in env:
            return "aws_profile"
        elif "CLAUDE_CODE_USE_BEDROCK" in env:
            # Default to api_key if only the provider flag is set
            return "api_key"

    return None


def get_preserved_settings(current_settings: dict | None) -> dict:
    """
    Extract non-standard settings that will be preserved.

    Returns: Dictionary of custom settings with their values.
    """
    if not current_settings:
        return {}

    # Base settings that are managed by the script
    base_keys = {
        "includeCoAuthoredBy",
        "permissions",
        "statusLine",
        "env",
        "apiKeyHelper",
    }

    # Return any settings not in base_keys
    return {k: v for k, v in current_settings.items() if k not in base_keys}
