#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/install-packages.sh"

resolved_zsh_path="$(resolve_zsh_path || true)"

packages=(stow zsh tmux starship fzf zsh-autosuggestions eza sesh)

if [ "$(uname -s)" = "Darwin" ]; then
  packages+=(ghostty)
elif [ "$(uname -s)" = "Linux" ]; then
  packages+=(build-essential)
fi

zsh_path="$(install_packages_auto --print-zsh-path "${packages[@]}")"

if [ -z "${zsh_path:-}" ]; then
  zsh_path="$resolved_zsh_path"
fi

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
  current_shell_path="${SHELL:-}"

  if [ ! -x "$current_shell_path" ] || [ "$current_shell_path" != "$zsh_path" ]; then
    if ! grep -q "$zsh_path" /etc/shells; then
      echo "Adding $zsh_path to /etc/shells (requires sudo)."
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi

    echo "Setting login shell to $zsh_path."
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

install_neovim_latest

stow_packages=(zsh tmux)

if [ "$(uname -s)" = "Darwin" ]; then
  stow_packages+=(aerospace hammerspoon)
fi

stow --dotfiles --target="$HOME" "${stow_packages[@]}"
stow --target="$HOME/.config" --ignore='^(zsh|tmux|aerospace|hammerspoon)$' .

if command -v zsh >/dev/null 2>&1 && [ -f "$HOME/.zshrc" ]; then
  ZDOTDIR="$HOME" zsh -i -c 'exit'
fi

if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

tmux start-server \; set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins"
"$HOME/.tmux/plugins/tpm/bin/install_plugins"

if command -v zsh >/dev/null 2>&1 && [ -f "$HOME/.zshrc" ] && [ -z "${SETUP_SKIP_SHELL_RELOAD:-}" ] && [ -t 0 ] && [ -t 1 ]; then
  echo "Reloading zsh to apply updated shell aliases."
  reload_zsh_path="${zsh_path:-}"

  if [ -z "$reload_zsh_path" ]; then
    reload_zsh_path="$(resolve_zsh_path || true)"
  fi

  if [ -n "$reload_zsh_path" ] && [ -x "$reload_zsh_path" ]; then
    exec "$reload_zsh_path" -i
  fi

  echo "Skipping zsh reload because no executable zsh path was resolved."
fi
