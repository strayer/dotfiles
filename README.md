# dotfiles

Personal configuration files, managed with [chezmoi](https://chezmoi.io). Uses Go templates for hostname-based multi-environment support across work and home machines.

## Setup

Prerequisites: `chezmoi`, `age`, `age-plugin-se`, `age-plugin-yubikey`.

One thing in this repo is encrypted with [age](https://age-encryption.org), decrypting against the identity at `~/.config/chezmoi/age-identity.txt`:

- `.chezmoisecrets.age` — YAML of static secrets (URLs, server addresses), decrypted on demand by the `chezmoi-secrets` helper.

The single inviolable rule: **the identity file must exist at that path before `chezmoi apply` runs**. If it doesn't, `chezmoi-secrets` cannot decrypt the static secrets. Recovery is just "place the identity, re-run apply" — no corrupted state, only missing files.

`dot-secret`'s runtime backends are not encrypted — they are generic, convention-based scripts that carry no store-specific details (see [Runtime secret access](#runtime-secret-access)).

### Adding a new machine

The SE key is hardware-bound and cannot be ferried over, so it has to be generated on the new machine and that machine has to be added as a recipient on an existing one before encrypted files can flow.

1. **On the new machine**, generate the SE identity:

   ```bash
   mkdir -p ~/.config/chezmoi
   age-plugin-se keygen -o ~/.config/chezmoi/age-identity.txt
   ```

   If carrying the YubiKey over, also drop its identity stub at `~/.config/chezmoi/age-identity-yubikey.txt` (run `age-plugin-yubikey` to print it).

2. **On an existing machine**, add the new machine as a recipient and re-encrypt:

   - Append the new SE recipient line (from the new machine's identity file) to `.chezmoisecrets-recipients.txt`.
   - Re-encrypt static secrets: `chezmoi-secrets edit`, save without changes.
   - Commit and push.

3. **Back on the new machine**, clone and apply in one command:

   ```bash
   chezmoi init --apply git@github.com:USER/dotfiles.git
   ```

   The identity from step 1 is already on disk, so every encrypted file decrypts as chezmoi processes it.

4. **Set up `dot-secret`** (see [Runtime secret access](#runtime-secret-access)): write the local backend selector, e.g. `echo onepassword > ~/.config/dot-secret/backend`, and make sure the machine's secret store holds the keys under that backend's convention.

### First-time setup (no existing machine yet)

Skip step 2 above. After step 1, add both recipient lines (SE + YubiKey) to `.chezmoisecrets-recipients.txt` directly in your local clone, run `chezmoi init --apply`, then seed initial secrets with `chezmoi-secrets edit`.

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
