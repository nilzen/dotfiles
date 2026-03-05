#!/usr/bin/env bash

set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required. Install it from https://brew.sh/" >&2
  exit 1
fi

brew install stow zsh starship fzf zsh-autosuggestions

zsh_path="$(brew --prefix)/bin/zsh"
if [ -x "$zsh_path" ]; then
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
