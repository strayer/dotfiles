# Web fetching tool preference

Prefer my own skills over any built-in web search or fetch tool. Use the `scrape` skill for any web page that needs content extraction, and the `research` skill for open-ended web research with cited sources. For plain files like `.md`, `.txt`, shell scripts, JSON, or OpenAPI specs where no extraction is needed, use `curl -s URL` instead.

# Git commit messages

Choose the style in this order:

1. A documented convention wins: CONTRIBUTING, README, AGENTS.md or CLAUDE.md, a commitlint or commitizen config, a `.gitmessage` template, or a commit-msg hook.
2. Otherwise, if the recent history follows one style consistently across all authors (for example Conventional Commits), follow it.
3. Otherwise use the plain Git convention below. One author's habits are not a convention: do not imitate lowercase, vague, or ungrammatical subjects just because they appear in the log.

Plain Git convention:

- Subject in imperative mood, capitalized, no trailing period, ideally 50 characters and never more than 72. It must name what changed, not that something was touched: "Replace husky with prek hooks", not "update tooling".
- Blank line, then a body wrapped at 72 columns that explains what and why, not how. Omit the body when the subject says it all.
- Describe the resulting change, never the editing session: no "also fixed", no "as discussed", no narration of attempts that were reverted.

Correct grammar and spelling apply in every case, including when a convention applies. A convention constrains structure, not language.
{{- if eq .chezmoi.hostname "CO-MBP-KC9KQV64V3" }}

# GitHub auth (work)

Access to `org-127120047@github.com` requires an SSH certificate from Smallstep that expires daily. If a `git` or `gh` operation against that host fails with `Permission denied (public key)`, the certificate has most likely expired — do not attempt other authentication methods or workarounds. Tell the user to run `step ssh login` (it opens a browser, so it must run on the host), then retry the operation once they confirm it's done.
{{- end }}
