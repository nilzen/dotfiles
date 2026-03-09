#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/install-packages.sh"

zsh_path="$(install_packages_auto --print-zsh-path stow zsh tmux starship fzf zsh-autosuggestions tree)"

if [ -n "${zsh_path:-}" ] && [ -x "$zsh_path" ]; then
  if ! grep -q "$zsh_path" /etc/shells; then
    echo "Adding $zsh_path to /etc/shells (requires sudo)."
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi

  if [ "$SHELL" != "$zsh_path" ]; then
    chsh -s "$zsh_path"
  fi
fi

stow --dotfiles --target="$HOME" zsh tmux
stow --target="$HOME/.config" --ignore='^(zsh|tmux)$' .
