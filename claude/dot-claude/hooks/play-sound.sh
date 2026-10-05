#!/usr/bin/env bash
# Play a notification sound by role (attention, done, error). Cross-platform, never fails a hook.
# Usage: play-sound.sh <name>   (plays ${CLAUDE_SOUNDS_DIR:-~/.claude/sounds}/<name>.wav)

file="${CLAUDE_SOUNDS_DIR:-$HOME/.claude/sounds}/${1:-done}.wav"
[ -f "$file" ] || exit 0

play() {
  if command -v afplay >/dev/null 2>&1; then
    afplay "$file"
  elif command -v paplay >/dev/null 2>&1; then
    paplay "$file"
  elif command -v pw-play >/dev/null 2>&1; then
    pw-play "$file"
  elif command -v aplay >/dev/null 2>&1; then
    aplay -q "$file"
  elif command -v ffplay >/dev/null 2>&1; then
    ffplay -nodisp -autoexit -loglevel quiet "$file"
  elif command -v powershell.exe >/dev/null 2>&1; then
    # WSL / Git Bash: SoundPlayer needs a Windows path
    local winpath
    winpath=$(command -v wslpath >/dev/null 2>&1 && wslpath -w "$file" || cygpath -w "$file" 2>/dev/null || echo "$file")
    powershell.exe -NoProfile -Command "(New-Object Media.SoundPlayer '$winpath').PlaySync()"
  fi
}

play >/dev/null 2>&1 &
exit 0
