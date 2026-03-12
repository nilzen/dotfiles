## Repository Overview

- This repo is a personal dotfiles repository, not a single app or library.
- Most changes are config edits plus setup automation in shell scripts.
- Primary top-level areas:
- `setup.sh` bootstraps packages, stows files, and installs tmux plugins.
- `setup-dev.sh` runs the normal setup, then installs `pre-commit`.
- `install-packages.sh` contains shared package-manager detection and install helpers.
- `nvim/` contains a LazyVim-based Neovim config written in Lua.
- `aerospace/`, `tmux/`, `zsh/`, `starship/`, `ghostty/`, and `opencode/` are stow packages.
- `opencode/node_modules/` and `.opencode/node_modules/` are vendor trees; do not edit them by hand.

## Rule Files

- No repo-level Cursor rules were found in `.cursor/rules/`.
- No `.cursorrules` file was found.
- No Copilot instructions file was found at `.github/copilot-instructions.md`.
- If any of those files are added later, treat them as higher-priority repo guidance.

## Build, Lint, And Test Commands

- There is no formal build pipeline in this repo.
- There is no dedicated unit test suite today.
- There is no single-test runner because there are no repository tests yet.
- Validation is done with targeted smoke checks and `pre-commit`.

### Primary Commands

- Initial machine setup: `./setup.sh`
- Dev tooling setup: `./setup-dev.sh`
- Install the git hook only: `pre-commit install`
- Run all configured pre-commit hooks: `pre-commit run --all-files`
- Run the configured security scan explicitly: `pre-commit run gitleaks --all-files`
- Run the security scan for specific files: `pre-commit run gitleaks --files setup.sh install-packages.sh`

### Shell Validation

- Syntax check all setup scripts: `bash -n setup.sh && bash -n setup-dev.sh && bash -n install-packages.sh`
- Syntax check one shell script: `bash -n setup.sh`
- If `shellcheck` is installed, lint all scripts: `shellcheck setup.sh setup-dev.sh install-packages.sh`
- If `shellcheck` is installed, lint one script: `shellcheck install-packages.sh`
- If `shfmt` is installed, format-check shell scripts: `shfmt -d setup.sh setup-dev.sh install-packages.sh`
- If `shfmt` is installed, format one shell script in place: `shfmt -w setup.sh`

### Neovim / Lua Validation

- Format all Lua config files: `stylua nvim`
- Format one Lua file: `stylua nvim/lua/plugins/lsp.lua`
- Smoke test the Neovim config from the repo root: `XDG_CONFIG_HOME="$PWD" nvim --headless '+qa'`
- If you only changed Lua config, run both: `stylua nvim && XDG_CONFIG_HOME="$PWD" nvim --headless '+qa'`

### JSON / Package Validation

- There are minimal `package.json` files in `opencode/` and `.opencode/` with no scripts.
- `npm test` and `npm run lint` are not defined there.
- If you edit those files, validate with a parser if needed: `python -m json.tool opencode/package.json >/dev/null`

### What To Run For Common Changes

- Shell-only changes: `bash -n` on edited scripts, then `pre-commit run --files ...` when possible.
- Neovim Lua changes: `stylua nvim` and `XDG_CONFIG_HOME="$PWD" nvim --headless '+qa'`.
- README or markdown changes: usually no automated check; proofread links and commands manually.
- Aerospace, tmux, starship, ghostty, or zsh config changes: prefer targeted syntax or smoke checks if available, otherwise manual review.

## Single-Test Guidance

- There is no true single-test command because no test framework is configured.
- For shell scripts, the nearest equivalent is a single-file syntax check: `bash -n path/to/script.sh`.
- For Lua config, the nearest equivalent is formatting one file with `stylua path/to/file.lua` plus a full Neovim startup smoke test.
- For pre-commit, the nearest equivalent is a single hook against selected files: `pre-commit run gitleaks --files <file>`.

## Repository-Specific Editing Guidance

- Edit the source dotfiles in the repo, not the symlinked files in `$HOME` or `$HOME/.config`.
- Preserve idempotency in setup scripts; rerunning `./setup.sh` should stay safe.
- Prefer incremental changes over broad rewrites; this repo is mostly personal config and small regressions are costly.
- Avoid touching vendor content under `node_modules/`.
- Keep top-level setup flow easy to read; these scripts are operational docs as much as code.

## Shell Style Guidelines

- Use `#!/usr/bin/env bash` for executable shell scripts.
- Keep `set -euo pipefail` at the top of scripts.
- Use lower_snake_case for function names and local variables.
- Use `local` inside functions for function-scoped variables.
- Quote variable expansions unless unquoted expansion is intentionally required.
- Prefer `command -v tool >/dev/null 2>&1` for command detection.
- Prefer explicit OS guards like `[ "$(uname -s)" = "Darwin" ]` for macOS-only behavior.
- Prefer explicit dependency guards like `command -v brew >/dev/null 2>&1` before Homebrew calls.
- Use arrays for dynamic package lists rather than space-delimited strings.
- Follow the existing pattern of collecting missing packages before installing them.
- Keep user-facing status messages short and consistent with existing `✅ Already installed: ...` output.
- Return non-zero on unsupported environments instead of silently continuing.

## Error Handling Expectations

- Fail fast by default; do not suppress errors without a reason.
- Guard optional behavior with `if` checks instead of allowing hard failures.
- When a failure is actionable, print a clear message before returning or exiting.
- Preserve current privilege boundaries; only use `sudo` where the script already requires it.
- Do not add destructive commands or cleanup steps unless clearly requested.

## Lua / Neovim Style Guidelines

- Format Lua with StyLua settings from `nvim/stylua.toml`.
- Current Lua style is 2-space indentation and 120-column width.
- Keep modules small and purpose-specific under `nvim/lua/config/` and `nvim/lua/plugins/`.
- Plugin specs should return Lua tables from each file.
- Use `opts = function(_, opts)` when extending existing plugin configuration.
- Mutate `opts` defensively with `opts.foo = opts.foo or {}` when appropriate.
- Use `require("...")` with double-quoted module names, matching existing files.
- Assume `vim` is a global; `.luarc.json` whitelists it for diagnostics.
- Prefer configuration data over custom logic when LazyVim already supports the option.
- Keep comments minimal; retain existing explanatory comments when they add context.

## Formatting Conventions By File Type

- Bash: preserve existing spacing, one logical step per block, and blank lines between phases.
- Lua: let `stylua` handle formatting instead of hand-aligning tables.
- TOML: preserve readable grouping and existing alignment only when it improves scanning.
- JSON: keep compact, valid JSON with double-quoted keys and values.
- Markdown: keep command examples runnable as written from the repo root.

## Naming And Layout Conventions

- Stow packages live at the repo root as directories like `zsh/`, `tmux/`, and `aerospace/`.
- Files intended for `$HOME` often use a `dot-` prefix inside a stow package, for example `zsh/dot-zshrc`.
- Config meant for `$HOME/.config` typically mirrors the final config directory structure directly.
- Shell helper functions use verb-oriented names like `detect_package_manager` and `install_packages_auto`.
- Keep new filenames descriptive and consistent with nearby files.

## Imports And Dependencies

- In shell, source shared helpers with an absolute script-dir pattern like the existing `script_dir` / `repo_root` logic.
- In Lua, keep `require` calls near the top-level entry point unless lazy-loading is intentional.
- Do not introduce a new dependency manager or framework unless the repo clearly needs it.
- For Neovim plugins, prefer LazyVim/lazy.nvim conventions already in use.

## Secrets And Local Machine Assumptions

- Be careful with paths that reference the local machine, especially under `$HOME`.
- Do not commit secrets, tokens, or machine-specific credentials.
- The repo already includes a 1Password SSH agent socket path in `zsh/dot-zshrc`; preserve privacy when editing nearby lines.
- Keep gitleaks compatibility in mind when adding environment variables or example secrets.

## Agent Workflow Recommendations

- Start with `git status --short` before editing if the task may overlap existing work.
- Read the whole file before patching; many files are short and intentionally simple.
- Prefer `apply_patch` for focused edits.
- After changes, run the smallest relevant validation command set from this file.
- In your final note, mention exactly which commands you ran and which you could not run.

## Good Defaults For Future Changes

- If adding a new shell script, copy the safety pattern from `setup.sh`.
- If adding new Neovim plugin config, place it in `nvim/lua/plugins/` as a separate focused module.
- If adding new machine setup logic, keep platform-specific behavior behind explicit OS checks.
- If adding checks, wire them through `pre-commit` when practical so the repo has a single entry point for validation.
