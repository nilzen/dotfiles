#!/usr/bin/env bash
stow --target="$HOME" zsh
stow --target="$HOME/.config" --ignore=zsh .
