#!/usr/bin/env bash

set -euo pipefail

LOG_STDERR=0

log() {
  if [ "${LOG_STDERR:-0}" -eq 1 ]; then
    echo "$@" >&2
  else
    echo "$@"
  fi
}

detect_package_manager() {
  if command -v brew >/dev/null 2>&1; then
    echo "brew"
    return 0
  fi

  if command -v apt-get >/dev/null 2>&1; then
    echo "apt"
    return 0
  fi

  if command -v pacman >/dev/null 2>&1; then
    echo "pacman"
    return 0
  fi

  return 1
}

resolve_zsh_path() {
  local candidate
  local candidates=()

  candidates+=(
    "/bin/zsh"
    "/usr/bin/zsh"
    "/usr/local/bin/zsh"
    "/opt/homebrew/bin/zsh"
  )

  if command -v zsh >/dev/null 2>&1; then
    candidates+=("$(command -v zsh)")
  fi

  for candidate in "${candidates[@]}"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
      echo "$candidate"
      return 0
    fi
  done

  return 1
}

install_neovim_latest() {
  local os
  local arch
  local archive_name
  local download_url
  local tmp_dir
  local archive_path
  local extracted_dir
  local install_dir="$HOME/.local/opt/neovim"
  local local_bin_dir="$HOME/.local/bin"

  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os-$arch" in
    Darwin-arm64|Darwin-aarch64)
      archive_name="nvim-macos-arm64.tar.gz"
      ;;
    Darwin-x86_64)
      archive_name="nvim-macos-x86_64.tar.gz"
      ;;
    Linux-aarch64|Linux-arm64)
      archive_name="nvim-linux-arm64.tar.gz"
      ;;
    Linux-x86_64)
      archive_name="nvim-linux-x86_64.tar.gz"
      ;;
    *)
      echo "Unsupported platform for Neovim install: $os/$arch" >&2
      return 1
      ;;
  esac

  download_url="https://github.com/neovim/neovim/releases/latest/download/$archive_name"
  tmp_dir="$(mktemp -d)"
  archive_path="$tmp_dir/$archive_name"
  extracted_dir="$tmp_dir/${archive_name%.tar.gz}"

  curl -fsSL "$download_url" -o "$archive_path"
  mkdir -p "$HOME/.local/opt" "$local_bin_dir"
  tar -xzf "$archive_path" -C "$tmp_dir"
  rm -rf "$install_dir"
  mv "$extracted_dir" "$install_dir"
  ln -sf "$install_dir/bin/nvim" "$local_bin_dir/nvim"

  if [ "$os" = "Darwin" ] && command -v xattr >/dev/null 2>&1; then
    xattr -dr com.apple.quarantine "$install_dir" >/dev/null 2>&1 || true
  fi

  rm -rf "$tmp_dir"
  log "Installed latest Neovim release"
}

install_packages_auto() {
  local print_zsh_path=0

  if [ "${1:-}" = "--print-zsh-path" ]; then
    print_zsh_path=1
    shift
  fi

  if [ $print_zsh_path -eq 1 ]; then
    LOG_STDERR=1
  fi

  local pkg_manager
  pkg_manager="$(detect_package_manager || true)"

  if [ -z "${pkg_manager:-}" ]; then
    echo "No supported package manager found (brew, apt-get, pacman)." >&2
    return 1
  fi

  if [ "$pkg_manager" = "apt" ]; then
    sudo apt-get update
  fi

  PKG_MANAGER="$pkg_manager"

  if [ "$pkg_manager" = "apt" ]; then
    local pkg
    local filtered=()
    local wants_starship=0

    for pkg in "$@"; do
      if [ "$pkg" = "starship" ]; then
        wants_starship=1
      else
        filtered+=("$pkg")
      fi
    done

    if [ ${#filtered[@]} -gt 0 ]; then
      install_packages "$pkg_manager" "${filtered[@]}"
    fi

    if [ $wants_starship -eq 1 ]; then
      if ! command -v starship >/dev/null 2>&1; then
        curl -fsSL https://starship.rs/install.sh | sh -s -- -y
      else
        log "✅ Already installed: starship"
      fi
    fi
  else
    install_packages "$pkg_manager" "$@"
  fi

  if [ $print_zsh_path -eq 1 ]; then
    resolve_zsh_path
  fi
}

install_packages() {
  local pkg_manager="$1"
  shift

  local pkg
  local missing=()
  local install_name

  case "$pkg_manager" in
    brew)
      for pkg in "$@"; do
        if ! brew list --formula "$pkg" >/dev/null 2>&1; then
          missing+=("$pkg")
        else
          log "✅ Already installed: $pkg"
        fi
      done
      if [ ${#missing[@]} -gt 0 ]; then
        brew install "${missing[@]}"
      fi
      ;;
    apt)
      for pkg in "$@"; do
        install_name="$pkg"
        if [ "$pkg" = "ghostty" ]; then
          log "Skipping unsupported apt package: ghostty"
          continue
        fi
        if [ "$pkg" = "zsh-autosuggestions" ]; then
          install_name="zsh-autosuggestions"
        fi
        if ! dpkg -s "$install_name" >/dev/null 2>&1; then
          missing+=("$install_name")
        else
          log "✅ Already installed: $install_name"
        fi
      done
      if [ ${#missing[@]} -gt 0 ]; then
        sudo apt-get install -y "${missing[@]}"
      fi
      ;;
    pacman)
      for pkg in "$@"; do
        install_name="$pkg"
        if [ "$pkg" = "ghostty" ]; then
          log "Skipping unsupported pacman package: ghostty"
          continue
        fi
        if ! pacman -Qi "$install_name" >/dev/null 2>&1; then
          missing+=("$install_name")
        else
          log "✅ Already installed: $install_name"
        fi
      done
      if [ ${#missing[@]} -gt 0 ]; then
        sudo pacman -Sy --noconfirm "${missing[@]}"
      fi
      ;;
    *)
      echo "No supported package manager found (brew, apt-get, pacman)." >&2
      return 1
      ;;
  esac
}
