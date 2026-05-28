function sb --description "Run commands in a safehouse sandbox"
    set -l sb_args
    set -l cmd_idx 0

    for i in (seq (count $argv))
        switch $argv[$i]
            case '-*'
                set -a sb_args $argv[$i]
            case '*'
                set cmd_idx $i
                break
        end
    end

    if test $cmd_idx -eq 0
        echo "Usage: sb [sandbox-options...] <command> [args...]"
        echo ""
        echo "Coding agents:"
        echo "  claude     Claude Code (Vertex AI, apiKeyHelper)"
        echo "  codex      OpenAI Codex"
        echo "  gemini     Gemini CLI (gcloud ADC)"
        echo ""
        echo "Any other command runs in a plain safehouse sandbox."
        echo ""
        echo "Sandbox options (passed to safehouse) go before the command."
        return 1
    end

    set -l cmd $argv[$cmd_idx]
    set -l cmd_args
    if test $cmd_idx -lt (count $argv)
        set cmd_args $argv[(math $cmd_idx + 1)..]
    end

    switch $cmd
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
            _with-agent-secrets
            _sb-coding-agent \
                $sb_args \
                $extra_args \
                --env-pass=FIRECRAWL_API_KEY,LINKUP_API_KEY \
                --add-dirs-ro="$HOME/.agents/skills" \
                claude $cmd_args

        case codex
            _with-agent-secrets
            _sb-coding-agent \
                $sb_args \
                --env-pass=FIRECRAWL_API_KEY,LINKUP_API_KEY \
                --add-dirs-ro="$HOME/.agents/skills" \
                codex $cmd_args

        case gemini
            set -lx NO_BROWSER true
            _sb-coding-agent \
                $sb_args \
                --add-dirs-ro="$HOME/.config/gcloud/application_default_credentials.json" \
                gemini $cmd_args

        case '*'
            safehouse $sb_args $cmd $cmd_args
    end
end
