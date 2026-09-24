# Web fetching tool preference

Prefer my own skills over any built-in web search or fetch tool. Use the `scrape` skill for any web page that needs content extraction, and the `research` skill for open-ended web research with cited sources. For plain files like `.md`, `.txt`, shell scripts, JSON, or OpenAPI specs where no extraction is needed, use `curl -s URL` instead.

# Git commit messages

Choose the style in this order:

1. A documented convention wins: CONTRIBUTING, README, AGENTS.md or CLAUDE.md, a commitlint or commitizen config, a `.gitmessage` template, or a commit-msg hook.
2. Otherwise inspect up to 20 recent non-merge commits on the default branch, plus any commits already on the branch you are adding to. If the branch already has commits, match their style. Otherwise use a structured convention such as Conventional Commits if a clear majority of the 20 use it, counting bot commits; treat a few plain outliers as noise, not as a mixed convention.
3. Otherwise use the plain Git convention below. It also fills any gap the chosen convention leaves unspecified.

Plain Git convention:

- Subject in imperative mood, capitalized, no trailing period, ideally 50 characters and never more than 72. It must name what changed, not that something was touched: "Replace husky with prek hooks", not "update tooling".
- Blank line, then a body wrapped at 72 columns explaining what changed and why. Omit the body when the subject says it all.
- Describe the resulting change, never the editing session: no "also fixed", no "as discussed", no narration of attempts that were reverted.

In every case keep subjects specific and grammatical with correct spelling, and follow the chosen convention's casing. Never copy vague or ungrammatical subjects because they appear in the log.
{{- if eq .chezmoi.hostname "CO-MBP-KC9KQV64V3" }}

# GitHub auth (work)

Access to `org-127120047@github.com` requires an SSH certificate from Smallstep that expires daily. If a `git` or `gh` operation against that host fails with `Permission denied (public key)`, the certificate has most likely expired — do not attempt other authentication methods or workarounds. Tell the user to run `step ssh login` (it opens a browser, so it must run on the host), then retry the operation once they confirm it's done.
{{- end }}
