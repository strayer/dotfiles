function _with-agent-secrets --no-scope-shadowing --description "Export coding-agent API keys into the caller's scope"
    # Coding-agent skills (research, scrape) need API keys at runtime —
    # LINKUP_API_KEY and FIRECRAWL_API_KEY. We resolve them on the host with
    # dot-secret and export them into the caller's function scope, instead of
    # mounting dot-secret + its impls into the sandbox. Two reasons:
    #
    # 1. dot-secret is a thin dispatcher; the actual impl talks to a backend
    #    (1Password, Keychain, an age-encrypted file, ...) and each backend
    #    pulls in its own dependencies — sockets, identity files, IPC. Mounting
    #    all of that into the sandbox would mean threading a new RO mount or
    #    hole for every backend the dispatcher might pick. Pre-fetching keeps
    #    the sandbox surface small.
    #
    # 2. If the agent is prompt-injected, an in-sandbox dot-secret means
    #    `dot-secret list` followed by `dot-secret get <every name>` is one
    #    tool call away. Pre-fetching exposes only the keys we explicitly
    #    ferry in; the rest of the secret store stays unreachable.
    #
    # We use --no-scope-shadowing so `set -fx` lands in the caller's function
    # scope. That gives us two properties at once: external commands started
    # from the caller (claude, codex, safehouse, ...) inherit the keys via
    # exported env, AND the keys are released as soon as the caller's function
    # returns. They never leak into the user's interactive shell.
    #
    # Sandboxed callers must additionally pass
    #   --env-pass=FIRECRAWL_API_KEY,LINKUP_API_KEY
    # to safehouse — otherwise safehouse strips env vars at the sandbox
    # boundary and the export above is wasted.

    command -q dot-secret; or return 0

    set -l __agent_secret
    if set __agent_secret (dot-secret get firecrawl_api_key 2>/dev/null)
            and test -n "$__agent_secret"
        set -fx FIRECRAWL_API_KEY $__agent_secret
    end
    if set __agent_secret (dot-secret get linkup_api_key 2>/dev/null)
            and test -n "$__agent_secret"
        set -fx LINKUP_API_KEY $__agent_secret
    end
    set -e __agent_secret
end
