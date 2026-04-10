function sandbox-claude
    set -l extra_args
    if test -f ~/.claude/settings.json
        # Allow gcloud ADC when using Vertex AI direct auth
        if jq -e '.env.CLAUDE_CODE_USE_VERTEX' ~/.claude/settings.json >/dev/null 2>&1
            and not jq -e '.env.CLAUDE_CODE_SKIP_VERTEX_AUTH' ~/.claude/settings.json >/dev/null 2>&1
            set extra_args --add-dirs-ro="$HOME/.config/gcloud/application_default_credentials.json"
        end
        # Allow apiKeyHelper script if configured
        set -l helper (jq -r '.apiKeyHelper // empty' ~/.claude/settings.json)
        if test -n "$helper"
            set -a extra_args --add-dirs-ro=(string replace '~' "$HOME" "$helper")
        end
    end
    _sandbox-coding-agent --enable=clipboard $extra_args claude $argv
end
