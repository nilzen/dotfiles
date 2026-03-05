#!/usr/bin/env bash

set -euo pipefail

install_brew_packages() {
  local pkg
  local missing=()
  for pkg in "$@"; do
    if ! brew list --formula "$pkg" >/dev/null 2>&1; then
      missing+=("$pkg")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    brew install "${missing[@]}"
  fi
}

install_apt_packages() {
  local pkg
  local missing=()
  for pkg in "$@"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      missing+=("$pkg")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    sudo apt-get install -y "${missing[@]}"
  fi
}

install_pacman_packages() {
  local pkg
  local missing=()
  for pkg in "$@"; do
    if ! pacman -Qi "$pkg" >/dev/null 2>&1; then
      missing+=("$pkg")
    fi
  done
  if [ ${#missing[@]} -gt 0 ]; then
    sudo pacman -Sy --noconfirm "${missing[@]}"
  fi
}

if command -v brew >/dev/null 2>&1; then
  install_brew_packages stow zsh starship fzf zsh-autosuggestions
  zsh_path="$(brew --prefix)/bin/zsh"
elif command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  install_apt_packages stow zsh fzf
  if ! command -v starship >/dev/null 2>&1; then
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y
  fi
  zsh_path="$(command -v zsh)"
elif command -v pacman >/dev/null 2>&1; then
  install_pacman_packages stow zsh starship fzf
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
