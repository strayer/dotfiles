"""Cache management for configure-claude"""

import json
from pathlib import Path

from platformdirs import user_cache_path

from custom_types import Cache

CACHE_PATH = user_cache_path("configure-claude", ensure_exists=True) / "cache.json"


def read_cache() -> Cache:
    """
    Read cached configuration values from previous runs.

    Cache structure:
    {
        "vertex": {
            "litellm": {"project_id": "...", "base_url": "..."},
            "direct": {"project_id": "..."}
        },
        "bedrock": {
            "api_key": {"aws_region": "us-east-1"},
            "aws_profile": {"aws_region": "us-east-1", "aws_profile": "..."}
        }
    }
    """
    if not CACHE_PATH.exists():
        return {}

    try:
        with CACHE_PATH.open() as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError):
        return {}


def write_cache(cache: Cache) -> None:
    """Write configuration values to cache for future runs."""
    with CACHE_PATH.open("w") as f:
        json.dump(cache, f, indent=2)
        _ = f.write("\n")


def get_cached_variables(
    cache: Cache, provider: str, auth_method: str
) -> dict | None:
    """
    Get cached variables for a specific provider and auth method.

    Args:
        cache: Full cache dictionary
        provider: Provider name ("vertex" or "bedrock")
        auth_method: Auth method name

    Returns:
        Cached variables dictionary, or None if not found
    """
    provider_cache = cache.get(provider)
    if provider_cache is None:
        return None
    return provider_cache.get(auth_method)
