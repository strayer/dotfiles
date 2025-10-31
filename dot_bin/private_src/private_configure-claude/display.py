"""Display and formatting functions"""

import json

from rich.console import Console
from rich.panel import Panel

console = Console()


def display_current_status(
    current_provider: str | None,
    current_auth: str | None,
    preserved_settings: dict,
) -> None:
    """Display current configuration status at startup."""
    # Build status content
    if current_provider and current_auth:
        provider_status = (
            f"[bold cyan]{current_provider}[/bold cyan] [dim]({current_auth})[/dim]"
        )
    elif current_provider:
        provider_status = (
            f"[bold cyan]{current_provider}[/bold cyan] "
            f"[dim](auth method unknown)[/dim]"
        )
    else:
        provider_status = "[yellow]Not configured[/yellow]"

    content = f"Provider: {provider_status}"

    # Add preserved settings if any
    if preserved_settings:
        content += "\n\n[bold]Additional Settings:[/bold]"
        for key, value in preserved_settings.items():
            if isinstance(value, (dict, list)):
                json_str = json.dumps(value, indent=2)
                # Indent the JSON for display
                indented = "\n".join(f"    {line}" for line in json_str.split("\n"))
                content += f"\n  [cyan]{key}[/cyan]:\n{indented}"
            else:
                content += f"\n  [cyan]{key}[/cyan]: {value}"

    # Display in a nice panel
    panel = Panel(
        content,
        title="[bold]Current Configuration[/bold]",
        border_style="blue",
        padding=(1, 2),
    )
    console.print(panel)
    console.print()


def display_success(provider: str, auth_method: str) -> None:
    """Display success message after configuration."""
    console.print(
        f"\n[green]✓[/green] Configured [bold]{provider}[/bold] ({auth_method})"
    )
