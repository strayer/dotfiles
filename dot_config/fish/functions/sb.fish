function sb --description "Run commands in a nono sandbox"
    set -l sb_args
    set -l cmd_idx 0
    set -l docker 0

    for i in (seq (count $argv))
        switch $argv[$i]
            case --docker
                # sb-level switch, not a nono flag: selects the docker-enabled
                # profile variant for coding agents. Don't forward to nono run.
                set docker 1
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
        echo ""
        echo "Any other command runs in a plain nono sandbox."
        echo ""
        echo "Options (go before the command):"
        echo "  --docker   Use the docker-enabled profile (claude/codex only);"
        echo "             default profiles block the container socket."
        echo "  Other -... flags are passed through to nono run."
        return 1
    end

    set -l cmd $argv[$cmd_idx]
    set -l cmd_args
    if test $cmd_idx -lt (count $argv)
        set cmd_args $argv[(math $cmd_idx + 1)..]
    end

    # Coding-agent skills (research, scrape) read FIRECRAWL_API_KEY / LINKUP_API_KEY
    # from the environment. _with-agent-secrets resolves them on the host and
    # exports them into this function's scope; we then hand each one to nono
    # explicitly via `--env-credential-map env://VAR VAR` so the key is injected
    # into the sandboxed child even if a profile later starts filtering env vars.
    # Only the coding agents get them — arbitrary `sb <cmd>` runs stay clean.
    set -l secret_args
    if contains -- $cmd claude codex
        _with-agent-secrets
        if set -q FIRECRAWL_API_KEY
            set -a secret_args --env-credential-map env://FIRECRAWL_API_KEY FIRECRAWL_API_KEY
        end
        if set -q LINKUP_API_KEY
            set -a secret_args --env-credential-map env://LINKUP_API_KEY LINKUP_API_KEY
        end
    end

    switch $cmd
        case claude
            # Model auth stays as-is: grant read access to whichever Vertex
            # credential path ~/.claude/settings.json points at. Everything else
            # (workdir, ~/.agents, ~/.global_gitignore, secretive, gh) is covered
            # by the claude-code profile.
            set -l extra_args
            if test -f ~/.claude/settings.json
                # gcloud ADC when using Vertex AI direct auth
                if jq -e '.env.CLAUDE_CODE_USE_VERTEX' ~/.claude/settings.json >/dev/null 2>&1
                        and not jq -e '.env.CLAUDE_CODE_SKIP_VERTEX_AUTH' ~/.claude/settings.json >/dev/null 2>&1
                    set extra_args --read-file="$HOME/.config/gcloud/application_default_credentials.json"
                end
                # apiKeyHelper script if configured
                set -l helper (jq -r '.apiKeyHelper // empty' ~/.claude/settings.json)
                if test -n "$helper"
                    set -a extra_args --read-file=(string replace '~' "$HOME" "$helper")
                end
            end
            set -l profile claude-code
            test $docker -eq 1; and set profile claude-code-docker
            nono run \
                --profile $profile \
                --allow-cwd \
                $sb_args \
                $extra_args \
                $secret_args \
                -- claude $cmd_args

        case codex
            # codex-cli (and -docker) build on codex-cli-base, which extends the
            # official always-further/codex pack (~/.codex auth) with the same
            # extras as claude-code (workdir, ~/.global_gitignore, secretive, gh).
            # The base carries no container rule; the default leaf denies the
            # docker socket, the -docker leaf allows it.
            set -l profile codex-cli
            test $docker -eq 1; and set profile codex-cli-docker
            nono run \
                --profile $profile \
                --allow-cwd \
                $sb_args \
                $secret_args \
                -- codex $cmd_args

        case '*'
            test $docker -eq 1
            and echo "sb: --docker only applies to the claude/codex agents; ignoring." >&2
            nono run --allow-cwd $sb_args -- $cmd $cmd_args
    end
end
