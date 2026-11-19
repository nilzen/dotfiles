#!/usr/bin/env bash
# Keep Claude Code sessions attached to their tmux panes across tmux-resurrect save/restore.
#
#   record   Claude SessionStart hook (reads hook JSON on stdin): stores the live session id
#            in the pane option @claude_session_id. Fires on startup, resume, clear and compact.
#   save     tmux-resurrect post-save-all hook: writes "session window pane id" for every pane
#            that is currently running claude.
#   restore  tmux-resurrect post-restore-all hook: runs `claude --resume <id>` in those panes.

set -uo pipefail

resurrect_dir="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
sessions_file="$resurrect_dir/claude_sessions.txt"
uuid_pattern='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
claude_command_pattern='^(claude|[0-9]+\.[0-9]+\.[0-9]+.*)$'
shell_command_pattern='^(zsh|bash|fish|sh)$'

record() {
  [ -n "${TMUX_PANE:-}" ] || exit 0
  local session_id
  session_id="$(jq -r '.session_id // empty')"
  [[ "$session_id" =~ $uuid_pattern ]] || exit 0
  tmux set-option -p -t "$TMUX_PANE" @claude_session_id "$session_id"
}

# Fallback for claude processes started before the hook existed. Claude writes
# ~/.claude/sessions/<pid>.json with the live sessionId; failing that, read `--resume <id>` from the args.
session_id_from_process() {
  local shell_pid="$1" child_pid args session_file id
  child_pid="$(ps -axo pid=,ppid= | awk -v parent="$shell_pid" '$2 == parent { print $1; exit }')"
  [ -n "$child_pid" ] || return 0
  session_file="$HOME/.claude/sessions/$child_pid.json"
  if [ -f "$session_file" ]; then
    id="$(jq -r '.sessionId // empty' "$session_file" 2>/dev/null)"
    if [[ "$id" =~ $uuid_pattern ]]; then
      printf '%s' "$id"
      return 0
    fi
  fi
  args="$(ps -o args= -p "$child_pid" 2>/dev/null)"
  if [[ "$args" =~ --resume[=\ ]([0-9a-fA-F-]{36}) ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  fi
}

save() {
  mkdir -p "$resurrect_dir"
  local temp_file
  temp_file="$(mktemp "$resurrect_dir/claude_sessions.XXXXXX")"
  local tab=$'\t' session window pane command pane_pid session_id
  while IFS="$tab" read -r session window pane command pane_pid session_id; do
    [[ "$command" =~ $claude_command_pattern ]] || continue
    [ -n "$session_id" ] || session_id="$(session_id_from_process "$pane_pid")"
    [[ "$session_id" =~ $uuid_pattern ]] || continue
    printf '%s\t%s\t%s\t%s\n' "$session" "$window" "$pane" "$session_id" >>"$temp_file"
  done < <(tmux list-panes -a -F "#{session_name}${tab}#{window_index}${tab}#{pane_index}${tab}#{pane_current_command}${tab}#{pane_pid}${tab}#{@claude_session_id}")
  mv "$temp_file" "$sessions_file"
}

restore() {
  [ -f "$sessions_file" ] || exit 0
  local tab=$'\t' session window pane session_id target command
  while IFS="$tab" read -r session window pane session_id; do
    [[ "$session_id" =~ $uuid_pattern ]] || continue
    target="${session}:${window}.${pane}"
    command="$(tmux display-message -p -t "$target" '#{pane_current_command}' 2>/dev/null)" || continue
    [[ "$command" =~ $shell_command_pattern ]] || continue
    tmux send-keys -t "$target" "claude --resume $session_id" Enter
  done <"$sessions_file"
}

case "${1:-}" in
  record) record ;;
  save) save ;;
  restore) restore ;;
  *) echo "usage: $0 record|save|restore" >&2; exit 2 ;;
esac
