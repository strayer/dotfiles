"""Entry point and orchestration for configure-claude"""

import click

from cache import get_cached_variables, read_cache, write_cache
from config import Provider
from display import display_current_status, display_success
from prompts import (
    collect_bedrock_variables,
    collect_vertex_variables,
    prompt_bedrock_auth,
    prompt_provider,
    prompt_vertex_auth,
)
from settings import (
    build_settings,
    detect_auth_method,
    detect_provider,
    get_preserved_settings,
    read_settings,
    write_settings,
)


@click.command()
def main() -> None:
    """Configure Claude Code settings for different LLM providers."""

    # 1. Read current settings and cache
    current = read_settings()
    current_provider = detect_provider(current)
    current_auth = (
        detect_auth_method(current, current_provider) if current_provider else None
    )
    cache = read_cache()

    # 2. Display current status
    preserved = get_preserved_settings(current)
    display_current_status(current_provider, current_auth, preserved)

    # 3. Prompt for provider and auth method
    provider: Provider = prompt_provider(current_provider)

    if provider == "vertex":
        auth_method = prompt_vertex_auth()
        cached_vars = get_cached_variables(cache, provider, auth_method)
        variables = collect_vertex_variables(auth_method, cached_vars)
    else:  # bedrock
        auth_method = prompt_bedrock_auth()
        cached_vars = get_cached_variables(cache, provider, auth_method)
        variables = collect_bedrock_variables(auth_method, cached_vars)

    # 4. Build new settings (merges base-settings.json + provider config)
    new_settings = build_settings(provider, auth_method, variables)

    # 5. Preserve custom settings from current config
    for key, value in preserved.items():
        new_settings[key] = value

    # 6. Write settings
    write_settings(new_settings)
    display_success(provider, auth_method)

    # 7. Update cache with new values (preserve all other cached configs)
    if provider not in cache:
        cache[provider] = {}
    cache[provider][auth_method] = variables
    write_cache(cache)


if __name__ == "__main__":
    main()
