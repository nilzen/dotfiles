# Dotfiles Repository 😎

This repository contains my dotfiles, used to configure my personal development
environment and tools. This is the central repository for managing my dotfiles.

## Using stow to manage dotfiles 🛠️

The repository uses [GNU Stow](https://www.gnu.org/software/stow/) to manage
and symlink files. To set up the dotfiles, ensure you have GNU Stow installed.
You can install it with your package manager:

- On Debian/Ubuntu:
  `sudo apt install stow`
- On macOS with Homebrew:
  `brew install stow`
- On Arch Linux:
  `sudo pacman -S stow`

🔑 **After installing Stow**, simply run the `setup.sh` script located in the
repository to initialize the symlinks for your development environment:

```bash
./setup.sh
```

This will take care of setting up everything for you! 🎉

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
