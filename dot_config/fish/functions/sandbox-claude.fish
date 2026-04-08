function sandbox-claude
    set -l extra_args
    # Allow gcloud ADC when using Vertex AI direct auth
    if test -f ~/.claude/settings.json
        and jq -e '.env.CLAUDE_CODE_USE_VERTEX' ~/.claude/settings.json >/dev/null 2>&1
        and not jq -e '.env.CLAUDE_CODE_SKIP_VERTEX_AUTH' ~/.claude/settings.json >/dev/null 2>&1
        set extra_args --add-dirs-ro="$HOME/.config/gcloud/application_default_credentials.json"
    end
    safe $extra_args claude $argv
end
