from custom_types import Provider, ProviderConfig

# Provider-specific environment variables and settings
PROVIDER_CONFIGS: dict[Provider, ProviderConfig] = {
    "vertex": {
        "common_env": {
            "CLOUD_ML_REGION": "global",
            "VERTEX_REGION_CLAUDE_4_0_SONNET": "europe-west1",
            "VERTEX_REGION_CLAUDE_4_5_SONNET": "europe-west1",
            "VERTEX_REGION_CLAUDE_4_5_HAIKU": "europe-west1",
            "CLAUDE_CODE_USE_VERTEX": "1",
            "ANTHROPIC_MODEL": "claude-sonnet-4-5@20250929",
            "ANTHROPIC_SMALL_FAST_MODEL": "claude-haiku-4-5@20251001",
        },
        "auth": {
            "litellm": {
                "env": {
                    "CLAUDE_CODE_SKIP_VERTEX_AUTH": "1",
                },
                "api_key_helper": "~/.bin/get-claude-code-api-key-vertex",
            },
            "direct": {
                "env": {},
                "api_key_helper": None,
            },
        },
    },
    "bedrock": {
        "common_env": {
            "CLAUDE_CODE_USE_BEDROCK": "1",
            "AWS_REGION": "eu-central-1",
            "ANTHROPIC_SMALL_FAST_MODEL_AWS_REGION": "us-east-1",
            "ANTHROPIC_DEFAULT_SONNET_MODEL": (
                "eu.anthropic.claude-sonnet-4-5-20250929-v1:0"
            ),
            "ANTHROPIC_DEFAULT_HAIKU_MODEL": (
                "us.anthropic.claude-3-5-haiku-20241022-v1:0"
            ),
        },
        "auth": {
            "api_key": {
                "env": {
                    "CLAUDE_CODE_SKIP_BEDROCK_AUTH": "1",
                },
                "api_key_helper": "~/.bin/get-claude-code-api-key-bedrock",
            },
            "aws_profile": {
                "env": {},
                "api_key_helper": None,
            },
        },
    },
}
