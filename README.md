# Dotfiles Repository 😎

This repository contains my dotfiles, used to configure my personal development
environment and tools. This is the central repository for managing my dotfiles.

## Setup 🛠️

Run the `setup.sh` script located in the repository to initialize the symlinks
for your development environment:

```bash
./setup.sh
```

This will take care of setting up everything for you! 🎉

The setup installs and stows:
- `zsh` (`~/.zshrc`)
- `tmux` (`~/.tmux.conf`)
- config folders under `~/.config` (for example `nvim`, `starship`, and `opencode`)

After setup, tmux plugin manager (TPM) is also installed at
`~/.tmux/plugins/tpm` if it is not already present.

OpenCode uses the Catppuccin theme via `~/.config/opencode/tui.json`.

## Dev environment setup (pre-commit + gitleaks) 🧪

If you want dev tooling (pre-commit + gitleaks), use the dev setup script:

```bash
./setup-dev.sh
```

This installs `pre-commit`, configures the git hook, and enables gitleaks checks
on every commit. You can also run a one-off scan:

```bash
pre-commit run gitleaks --all-files
```
