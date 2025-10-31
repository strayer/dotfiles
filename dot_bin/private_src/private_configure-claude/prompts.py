"""User interaction and input prompts"""

from rich.console import Console
from rich.prompt import Prompt

from custom_types import Provider

console = Console()


def prompt_provider(current_provider: Provider | None) -> Provider:
    """Prompt user to select provider."""
    console.print("[bold]Select LLM Provider[/bold]")

    choice = Prompt.ask(
        "Choose provider",
        choices=["vertex", "bedrock"],
        default=current_provider,
    )
    return choice  # type: ignore[return-value]


def prompt_vertex_auth() -> str:
    """Prompt for Vertex auth method."""
    console.print("\n[bold]Vertex AI Authentication[/bold]")
    choice = Prompt.ask("Auth method", choices=["litellm", "direct"], default="litellm")
    return choice


def prompt_bedrock_auth() -> str:
    """Prompt for Bedrock auth method."""
    console.print("\n[bold]AWS Bedrock Authentication[/bold]")
    choice = Prompt.ask(
        "Auth method", choices=["api_key", "aws_profile"], default="api_key"
    )
    return choice


def collect_vertex_variables(
    auth_method: str, cached_values: dict | None
) -> dict:
    """Collect required Vertex variables from user, using cached values as defaults."""
    console.print("\n[bold]Vertex AI Configuration[/bold]")

    project_id = Prompt.ask(
        "GCP Project ID", default=(cached_values or {}).get("project_id", "")
    )

    if auth_method == "litellm":
        base_url = Prompt.ask(
            "LiteLLM Base URL", default=(cached_values or {}).get("base_url", "")
        )
        return {"project_id": project_id, "base_url": base_url}

    return {"project_id": project_id}


def collect_bedrock_variables(
    auth_method: str, cached_values: dict | None
) -> dict:
    """Collect required Bedrock variables from user, using cached values as defaults."""
    console.print("\n[bold]AWS Bedrock Configuration[/bold]")

    if auth_method == "aws_profile":
        aws_profile = Prompt.ask(
            "AWS Profile",
            default=(cached_values or {}).get("aws_profile", "")
        )
        return {"aws_profile": aws_profile}

    return {}
