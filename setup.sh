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

stow --dotfiles --target="$HOME" zsh tmux aerospace
stow --target="$HOME/.config" --ignore='^(zsh|tmux|aerospace)$' .

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

tmux start-server \; set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins"
"$HOME/.tmux/plugins/tpm/bin/install_plugins"
