#!/usr/bin/env bash

set -euo pipefail

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

install_packages_auto() {
  local print_zsh_path=0
  if [ "${1:-}" = "--print-zsh-path" ]; then
    print_zsh_path=1
    shift
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
        echo "✅ Already installed: starship"
      fi
    fi
  else
    install_packages "$pkg_manager" "$@"
  fi

  if [ $print_zsh_path -eq 1 ]; then
    if [ "$pkg_manager" = "brew" ]; then
      echo "$(brew --prefix)/bin/zsh"
    else
      echo "$(command -v zsh)"
    fi
  fi
}

install_packages() {
  local pkg_manager="$1"
  shift

  local pkg
  local missing=()

  case "$pkg_manager" in
    brew)
      for pkg in "$@"; do
        if ! brew list --formula "$pkg" >/dev/null 2>&1; then
          missing+=("$pkg")
        else
          echo "✅ Already installed: $pkg"
        fi
      done
      if [ ${#missing[@]} -gt 0 ]; then
        brew install "${missing[@]}"
      fi
      ;;
    apt)
      for pkg in "$@"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
          missing+=("$pkg")
        else
          echo "✅ Already installed: $pkg"
        fi
      done
      if [ ${#missing[@]} -gt 0 ]; then
        sudo apt-get install -y "${missing[@]}"
      fi
      ;;
    pacman)
      for pkg in "$@"; do
        if ! pacman -Qi "$pkg" >/dev/null 2>&1; then
          missing+=("$pkg")
        else
          echo "✅ Already installed: $pkg"
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
