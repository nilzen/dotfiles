#!/bin/bash
# UserPromptSubmit hook: "/code" opens VS Code Insiders in the session cwd without an API call.
input=$(cat)
prompt=$(printf '%s' "$input" | jq -r '.prompt // ""' | tr -d '[:space:]')
[ "$prompt" = "/code" ] || exit 0
dir=$(printf '%s' "$input" | jq -r '.cwd // empty')
open -a "Visual Studio Code - Insiders" "${dir:-$PWD}"
echo '{"decision":"block","reason":"Opened VS Code Insiders"}'
