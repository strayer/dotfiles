function sb --description "Run commands in a safehouse sandbox"
    if test (count $argv) -eq 0
        echo "Usage: sb <command> [args...]"
        echo ""
        echo "Coding agents:"
        echo "  claude     Claude Code (Vertex AI, apiKeyHelper)"
        echo "  codex      OpenAI Codex"
        echo "  gemini     Gemini CLI (gcloud ADC)"
        echo ""
        echo "Any other command runs in a plain safehouse sandbox."
        return 1
    end

    switch $argv[1]
        case claude
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
            _sb-coding-agent $extra_args claude $argv[2..]

        case codex
            _sb-coding-agent codex $argv[2..]

        case gemini
            set -lx NO_BROWSER true
            _sb-coding-agent \
                --add-dirs-ro="$HOME/.config/gcloud/application_default_credentials.json" \
                gemini $argv[2..]

        case '*'
            safehouse $argv
    end
end
