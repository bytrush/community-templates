#!/usr/bin/env bash
set -euo pipefail

theme_file="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/themes/noctalia.conf"

if [ -f "$HOME/.tmux.conf" ]; then
  config_file="$HOME/.tmux.conf"
elif [ -n "${XDG_CONFIG_HOME:-}" ] && [ -f "$XDG_CONFIG_HOME/tmux/tmux.conf" ]; then
  config_file="$XDG_CONFIG_HOME/tmux/tmux.conf"
elif [ -f "$HOME/.config/tmux/tmux.conf" ]; then
  config_file="$HOME/.config/tmux/tmux.conf"
else
  # Nothing was edited, so there is nothing to undo.
  exit 0
fi

tmp_file="$(mktemp "${config_file}.tmp.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT

awk '
  /^[[:space:]]*source(-file)?[[:space:]]/ && index($0, "tmux/themes/noctalia.conf") { next }
  { print }
' "$config_file" >"$tmp_file"

if ! cmp -s "$config_file" "$tmp_file"; then
  cat "$tmp_file" >"$config_file"
fi

rm -f -- "$theme_file"
