#!/bin/bash
# Claude Code statusline: model name, context usage, and session cost.
# Managed by the "statusline-setup" agent. Ask Claude to run that agent to
# change this script further.

input=$(cat)

model_name=$(echo "$input" | jq -r '.model.display_name // "Claude"')
effort_level=$(echo "$input" | jq -r '.effort.level // empty')

if [ -n "$effort_level" ] && [ "$effort_level" != "null" ]; then
  model_name="${model_name} (${effort_level})"
fi

context_window_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
tokens_used=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

fmt_tokens() {
  awk -v n="$1" 'BEGIN { printf (n >= 1000) ? "%.0fk" : "%d", (n >= 1000) ? n / 1000 : n }'
}

if [ -n "$tokens_used" ] && [ -n "$context_window_size" ]; then
  tokens_used_str=$(fmt_tokens "$tokens_used")
  context_window_size_str=$(fmt_tokens "$context_window_size")
  if [ -n "$used_pct" ] && [ "$used_pct" != "null" ]; then
    context_str=$(printf "%s/%s tok (%.0f%%)" "$tokens_used_str" "$context_window_size_str" "$used_pct")
  else
    context_str="${tokens_used_str}/${context_window_size_str} tok"
  fi
else
  context_str="n/a"
fi

# "cost" is not part of the documented statusline schema in this environment,
# but Claude Code has historically included a cost.total_cost_usd field.
# Fall back gracefully if it is absent.
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
if [ -n "$cost" ] && [ "$cost" != "null" ]; then
  cost_str=$(printf "\$%.2f" "$cost")
else
  cost_str="n/a"
fi

printf "\033[2m%s\033[0m \033[2m|\033[0m \033[2mCtx: %s\033[0m \033[2m|\033[0m \033[2mCost: %s\033[0m" \
  "$model_name" "$context_str" "$cost_str"
