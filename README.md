# dotfiles

Personal configuration files, managed with [chezmoi](https://chezmoi.io). Uses Go templates for hostname-based multi-environment support across work and home machines.

## Setup

Prerequisite: **[Homebrew](https://brew.sh)** — everything else is installed from it (see [Provisioning a new machine](#provisioning-a-new-machine)).

One thing in this repo is encrypted with [age](https://age-encryption.org), decrypting against the identity at `~/.config/chezmoi/age-identity.txt`:

- `.chezmoisecrets.age` — YAML of static secrets (URLs, server addresses), decrypted on demand by the `chezmoi-secrets` helper.

The single inviolable rule: **the identity file must exist at that path before `chezmoi apply` runs**. If it doesn't, `chezmoi-secrets` cannot decrypt the static secrets. Recovery is just "place the identity, re-run apply" — no corrupted state, only missing files.

`dot-secret`'s runtime backends are not encrypted — they are generic, convention-based scripts that carry no store-specific details (see [Runtime secret access](#runtime-secret-access)).

### Provisioning a new machine

The age identity must exist at `~/.config/chezmoi/age-identity.txt` before apply. It is generated per-machine (it cannot be copied) and registered as a recipient elsewhere.

1. Install [Homebrew](https://brew.sh), then bootstrap: `brew install chezmoi age`

2. Create `~/.config/chezmoi/age-identity.txt` — pick one:

   - **Secure Enclave** — `age-plugin-se keygen -o ~/.config/chezmoi/age-identity.txt`
   - **YubiKey** — write the stub printed by `age-plugin-yubikey`
   - **Password-backed** — `age-keygen | age -p -o ~/.config/chezmoi/age-identity.txt` (passphrase-encrypted key; age prompts for it on apply)

3. Register it as a recipient on an existing machine: append the recipient line to `.chezmoisecrets-recipients.txt`, run `chezmoi-secrets edit` (save to re-encrypt), commit, push. _First machine? Add the line in your local clone instead, then seed secrets with `chezmoi-secrets edit` after step 4._

4. Clone and apply: `chezmoi init --apply git@github.com:USER/dotfiles.git`

5. Install packages: `brew bundle --file ~/.local/share/chezmoi/Brewfile`

6. Set fish as login shell: `command -v fish | sudo tee -a /etc/shells && chsh -s "$(command -v fish)"`

7. Select the `dot-secret` backend: `echo onepassword > ~/.config/dot-secret/backend` (see [Runtime secret access](#runtime-secret-access)).

## Secrets management

Static secrets live in `.chezmoisecrets.age`. The `[secret]` block in `.chezmoi.toml.tmpl` calls a `chezmoi-secrets` wrapper that decrypts on demand. Templates read values with:

```
{{ (secret | fromYaml).some_key | quote }}
```

To update:

```bash
chezmoi-secrets edit    # modify values, save
chezmoi diff            # verify rendered templates
```

Commit `.chezmoisecrets.age` and push. Other machines pick up changes on the next `chezmoi update`.

## Runtime secret access

Short-lived automation secrets (API keys for tooling, agent skills, etc.) go through `dot-secret` instead of being stored in shell startup files or `~/.claude/settings.json`.

```bash
dot-secret list
dot-secret get linkup_api_key
dot-secret set firecrawl_api_key
```

The public command is a stable dispatcher: it reads a backend name from a **local** selector at `~/.config/dot-secret/backend` and execs the matching implementation under `~/.config/dot-secret/impls/<backend>`. The impls are generic, convention-based scripts managed by chezmoi from `dot_config/dot-secret/impls/` — they contain no vault names, item names, or other store-specific details, so they are safe to keep in this public repo. Each backend stores secrets at a derivable location:

| Backend | Selector | Convention |
|---|---|---|
| 1Password | `onepassword` | `op://dot-secret/<name>/credential` (dedicated `dot-secret` vault) |
| macOS Keychain | `keychain` | generic-password, service `dot-secret.<name>`, account `$USER` |

The selector is kept **local** (not committed) so the repo never reveals which machine uses which password manager. Set it once per machine, e.g. `echo onepassword > ~/.config/dot-secret/backend`. New backends (e.g. `pass` for non-hardware systems like WSL) drop in as additional `impls/<backend>` scripts.
