#!/usr/bin/env bash
set -euo pipefail

template_dir="$(cd "$(dirname "$0")" && pwd)"
work_dir="$(mktemp -d)"
config_home="$work_dir/config"
cli="$config_home/opencode/cli.json"
state="$config_home/opencode/.noctalia-theme-mode"
theme="$config_home/opencode/themes/matugen.json"

cleanup() {
    rm -rf "$work_dir"
}
trap cleanup EXIT

mkdir -p "$config_home/opencode/themes"

run_apply() {
    XDG_CONFIG_HOME="$config_home" bash "$template_dir/apply.sh" "$1" 2>/dev/null
}

run_undo() {
    XDG_CONFIG_HOME="$config_home" bash "$template_dir/undo.sh" 2>/dev/null
}

# The generated theme is selected: sync the mode and preserve other settings.
cat >"$cli" <<'EOF'
{
  "theme": {
    "name": "matugen",
    "mode": "system"
  },
  "other": true
}
EOF
printf '{}\n' >"$theme"

run_apply light
[[ "$(jq -r '.theme.mode' "$cli")" == "light" ]]
[[ "$(cat "$state")" == "system" ]]
[[ "$(jq -r '.other' "$cli")" == "true" ]]

run_apply dark
[[ "$(jq -r '.theme.mode' "$cli")" == "dark" ]]
[[ "$(cat "$state")" == "system" ]]

run_undo
[[ "$(jq -r '.theme.mode' "$cli")" == "system" ]]
[ ! -e "$state" ]
[ ! -e "$theme" ]

# Undo must be idempotent.
run_undo

# A different theme is selected: leave cli.json alone.
cat >"$cli" <<'EOF'
{
  "theme": {
    "name": "kanagawa",
    "mode": "system"
  }
}
EOF
run_apply light
[[ "$(jq -r '.theme.mode' "$cli")" == "system" ]]
[ ! -e "$state" ]

# If the user switched away from matugen, undo must not rewrite their mode.
cat >"$cli" <<'EOF'
{
  "theme": {
    "name": "matugen",
    "mode": "system"
  }
}
EOF
printf '{}\n' >"$theme"
run_apply light
jq '.theme.name = "kanagawa" | .theme.mode = "dark"' "$cli" >"$cli.tmp" && mv "$cli.tmp" "$cli"
run_undo
[[ "$(jq -r '.theme.mode' "$cli")" == "dark" ]]
[ ! -e "$state" ]
[ ! -e "$theme" ]

# Missing cli.json: warn and exit 0 without creating it.
rm -f "$cli"
run_apply dark
[ ! -e "$cli" ]

# Current mode already matches: no state file is needed.
cat >"$cli" <<'EOF'
{
  "theme": {
    "name": "matugen",
    "mode": "light"
  }
}
EOF
run_apply light
[ ! -e "$state" ]
