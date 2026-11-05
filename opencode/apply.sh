#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"
case "$mode" in
    light|dark) ;;
    *)
        echo "Usage: apply.sh (dark|light)" >&2
        exit 1
        ;;
esac

config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
config_file="$config_dir/cli.json"
state_file="$config_dir/.noctalia-theme-mode"

if [ ! -f "$config_file" ]; then
    echo "OpenCode cli.json not found at $config_file; skipping theme mode sync" >&2
    exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found; skipping OpenCode theme mode sync" >&2
    exit 0
fi

if ! theme_name="$(jq -r '.theme.name // empty' "$config_file")"; then
    echo "Could not parse $config_file; skipping theme mode sync" >&2
    exit 0
fi

# Leave the mode alone unless the user selected the generated theme.
if [ "$theme_name" != "matugen" ]; then
    exit 0
fi

if ! current_mode="$(jq -r '.theme.mode // "system"' "$config_file")"; then
    echo "Could not read theme.mode from $config_file; skipping theme mode sync" >&2
    exit 0
fi

if [ "$current_mode" = "$mode" ]; then
    exit 0
fi

# Remember the mode the user had before the first sync, so undo can restore it.
if [ ! -e "$state_file" ]; then
    printf '%s\n' "$current_mode" >"$state_file"
fi

tmp_file="$(mktemp "${config_file}.tmp.XXXXXX")"
trap 'rm -f "$tmp_file"' EXIT

jq --arg mode "$mode" '.theme.mode = $mode' "$config_file" >"$tmp_file"
if ! cmp -s "$config_file" "$tmp_file"; then
    cat "$tmp_file" >"$config_file"
fi
