function claude --description "Run Claude Code with coding-agent API keys"
    _with-agent-secrets
    command claude $argv
end
