#!/usr/bin/env bash

set -euo pipefail

if command -v brew >/dev/null 2>&1; then
  brew install stow zsh starship fzf zsh-autosuggestions
  zsh_path="$(brew --prefix)/bin/zsh"
elif command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y stow zsh fzf
  if ! command -v starship >/dev/null 2>&1; then
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
  fi
  zsh_path="$(command -v zsh)"
elif command -v pacman >/dev/null 2>&1; then
  sudo pacman -Sy --noconfirm stow zsh starship fzf
  zsh_path="$(command -v zsh)"
else
  echo "No supported package manager found (brew, apt-get, pacman)." >&2
  exit 1
fi

if [ -n "${zsh_path:-}" ] && [ -x "$zsh_path" ]; then
  if ! grep -q "$zsh_path" /etc/shells; then
    echo "Adding $zsh_path to /etc/shells (requires sudo)."
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi

  if [ "$SHELL" != "$zsh_path" ]; then
    chsh -s "$zsh_path"
  fi
fi

stow --target="$HOME" zsh
stow --target="$HOME/.config" --ignore=zsh .
