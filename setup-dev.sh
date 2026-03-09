#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$repo_root/install-packages.sh"

"$repo_root/setup.sh"

install_packages_auto pre-commit

pre-commit install
