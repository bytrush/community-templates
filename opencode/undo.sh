#!/usr/bin/env bash
set -euo pipefail

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
config_file="$config_dir/cli.json"
state_file="$config_dir/.noctalia-theme-mode"
theme_file="$config_dir/themes/matugen.json"

[ -f "$state_file" ] || exit 0

if [ ! -f "$config_file" ]; then
    rm -f -- "$state_file"
    exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found; cannot restore OpenCode theme mode" >&2
    exit 0
fi

if ! current_theme="$(jq -r '.theme.name // empty' "$config_file")"; then
    echo "Could not parse $config_file; skipping theme mode restore" >&2
    exit 0
fi

# If the user switched away from the generated theme, do not overwrite their
# current mode; just remove the generated theme and the undo state.
if [ "$current_theme" != "matugen" ]; then
    rm -f -- "$state_file" "$theme_file"
    exit 0
fi

original_mode="$(cat "$state_file")"
case "$original_mode" in
    light|dark|system) ;;
    *) original_mode=system ;;
esac

tmp_file="$(mktemp "${config_file}.tmp.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT

jq --arg mode "$original_mode" '.theme.mode = $mode' "$config_file" >"$tmp_file"
if ! cmp -s "$config_file" "$tmp_file"; then
    cat "$tmp_file" >"$config_file"
fi

rm -f -- "$state_file" "$theme_file"
