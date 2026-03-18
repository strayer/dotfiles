# dotfiles

Personal configuration files, managed with [chezmoi](https://chezmoi.io). Uses Go templates for hostname-based multi-environment support across work and home machines.

## Setup

Prerequisites: `chezmoi`, `age`, `age-plugin-se`, `age-plugin-yubikey`

```bash
chezmoi init git@github.com:USER/dotfiles.git
chezmoi apply --init
```

The `--init` flag regenerates the chezmoi config from the source template before applying, which is necessary on first run to configure the secrets backend.

## Secrets management

Secrets (API URLs, server addresses) are stored in `.chezmoisecrets.age` — a YAML file encrypted with [age](https://age-encryption.org). Each machine has a Secure Enclave key via `age-plugin-se` and a YubiKey backup via `age-plugin-yubikey`. The file is encrypted for all recipients, so any single key can decrypt it.

Chezmoi's `[secret]` config calls a wrapper script (`chezmoi-secrets`) that decrypts and outputs the YAML. Templates access values with:

```
{{ (secret | fromYaml).some_key | quote }}
```

### Generating keys

Secure Enclave:

```bash
mkdir -p ~/.config/chezmoi
age-plugin-se keygen -o ~/.config/chezmoi/age-identity.txt
```

YubiKey:

```bash
age-plugin-yubikey
# Save identity output to ~/.config/chezmoi/age-identity-yubikey.txt
```

Add both recipient lines (from the identity files) to `.chezmoisecrets-recipients.txt` in the repo root.

### Creating initial secrets

```bash
chezmoi-secrets edit
```

This opens your `$EDITOR` with an empty file. Write your secrets as YAML:

```yaml
atuin_sync_server: https://atuin.example.com
mealplan_url: https://mealplan.example.com/api
```

Save and close. The script encrypts to all recipients and writes `.chezmoisecrets.age`.

### Adding a new machine

1. On the new machine, generate SE and YubiKey identities (see above)
2. On an existing machine, add the new recipient lines to `.chezmoisecrets-recipients.txt`
3. Re-encrypt for all recipients — run `chezmoi-secrets edit`, save without changes
4. Commit and push `.chezmoisecrets.age` and `.chezmoisecrets-recipients.txt`
5. On the new machine:

```bash
chezmoi init git@github.com:USER/dotfiles.git
chezmoi apply --init
```

### Updating secrets

```bash
chezmoi-secrets edit    # modify values, save
chezmoi diff            # verify rendered templates
```

Commit `.chezmoisecrets.age` and push. Other machines pick up changes on next `chezmoi update`.
