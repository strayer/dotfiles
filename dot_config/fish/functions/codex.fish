function codex --description "Run Codex with coding-agent API keys"
    _with-agent-secrets
    command codex $argv
end
