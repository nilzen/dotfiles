#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/install-packages.sh"

zsh_path="$(install_packages_auto --print-zsh-path stow zsh tmux starship fzf zsh-autosuggestions tree)"

if [ "$(uname -s)" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
  if ! brew list --cask aerospace >/dev/null 2>&1; then
    brew install --cask nikitabobko/tap/aerospace
  else
    echo "✅ Already installed: aerospace"
  fi

  if ! brew list --cask hammerspoon >/dev/null 2>&1; then
    brew install --cask hammerspoon
  else
    echo "✅ Already installed: hammerspoon"
  fi

  if ! brew list --cask ghostty >/dev/null 2>&1; then
    brew install --cask ghostty
  else
    echo "✅ Already installed: ghostty"
  fi
fi

if [ -n "${zsh_path:-}" ] && [ -x "$zsh_path" ]; then
  current_shell_name="$(basename "${SHELL:-}")"

  if [ "$current_shell_name" != "zsh" ]; then
    if ! grep -q "$zsh_path" /etc/shells; then
      echo "Adding $zsh_path to /etc/shells (requires sudo)."
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    chsh -s "$zsh_path"
  fi
fi

if [ -e "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ]; then
  backup_path="$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
  mv "$HOME/.zshrc" "$backup_path"
  echo "Backed up existing .zshrc to $backup_path"
fi

if [ ! -d "$HOME/.config" ]; then
  mkdir "$HOME/.config"
fi

stow --dotfiles --target="$HOME" zsh tmux aerospace hammerspoon
stow --target="$HOME/.config" --ignore='^(zsh|tmux|aerospace|hammerspoon)$' .

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

tmux start-server \; set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins"
"$HOME/.tmux/plugins/tpm/bin/install_plugins"
