#!/usr/bin/env bash
set -euo pipefail

tmux_dir="$(cd "$(dirname "$0")" && pwd)"
work_dir="$(mktemp -d)"
socket_dir="$work_dir/sockets"
socket_name="noctalia-theme-test-$$"
wrapper_socket="noctalia-wrapper-test-$$"

cleanup() {
    TMUX_TMPDIR="$socket_dir" tmux -L "$socket_name" kill-server 2>/dev/null || true
    TMUX_TMPDIR="$socket_dir" tmux -L "$wrapper_socket" kill-server 2>/dev/null || true
    rm -rf "$work_dir"
}
trap cleanup EXIT

mkdir -p "$socket_dir"

render_theme() {
    local output="$1"
    mkdir -p "$(dirname "$output")"
    sed \
        -e 's/{{ colors.surface_container_low.default.hex }}/#111111/g' \
        -e 's/{{ colors.surface_container.default.hex }}/#222222/g' \
        -e 's/{{[^}]*}}/#333333/g' \
        "$tmux_dir/tmux.conf" >"$output"
}

tmux_test() {
    TMUX_TMPDIR="$socket_dir" tmux -L "$socket_name" "$@"
}

# Style and terminal-palette options.
theme_file="$work_dir/theme.conf"
render_theme "$theme_file"

tmux_test -f /dev/null new-session -d
tmux_test set -g @noctalia_inactive_tabs_use_background off
tmux_test source-file "$theme_file"
[[ "$(tmux_test show-options -gv window-status-style)" != *bg=* ]]
[[ "$(tmux_test show-options -gv window-style)" == *"bg=#333333"* ]]
[[ "$(tmux_test show-options -gv window-active-style)" == *"bg=#333333"* ]]
[[ "$(tmux_test show-options -gv 'pane-colours[0]')" == "#333333" ]]
[[ "$(tmux_test show-options -gv 'pane-colours[15]')" == "#333333" ]]

tmux_test set -g @noctalia_inactive_tabs_use_background on
tmux_test source-file "$theme_file"
[[ "$(tmux_test show-options -gv window-status-style)" == *bg=#222222* ]]

tmux_test set -g @noctalia_window_style off
tmux_test source-file "$theme_file"
[[ "$(tmux_test show-options -gv window-style)" == "default" ]]
[[ "$(tmux_test show-options -gv window-active-style)" == "default" ]]

tmux_test kill-server 2>/dev/null || true

# apply.sh must update a server started through a wrapper config even though
# #{config_files} only reports the wrapper, not the user's tmux.conf.
test_home="$work_dir/home"
test_config="$work_dir/config"
test_theme="$test_config/tmux/themes/noctalia.conf"
mkdir -p "$test_home" "$test_config/tmux"
printf '# user tmux config\n' >"$test_config/tmux/tmux.conf"
printf 'source-file "%s"\n' "$test_config/tmux/tmux.conf" >"$test_home/wrapper.conf"
render_theme "$test_theme"

HOME="$test_home" \
    XDG_CONFIG_HOME="$test_config" \
    TMUX_TMPDIR="$socket_dir" \
    tmux -L "$wrapper_socket" -f "$test_home/wrapper.conf" new-session -d

# Confirm the scenario really is the wrapper case: the nested user config is
# not listed in #{config_files}.
config_files="$(TMUX_TMPDIR="$socket_dir" tmux -L "$wrapper_socket" display-message -p '#{config_files}')"
[[ "$config_files" == *"$test_home/wrapper.conf"* ]]
[[ "$config_files" != *"$test_config/tmux/tmux.conf"* ]]

HOME="$test_home" \
    XDG_CONFIG_HOME="$test_config" \
    TMUX_TMPDIR="$socket_dir" \
    bash "$tmux_dir/apply.sh" >/dev/null

[[ "$(TMUX_TMPDIR="$socket_dir" tmux -L "$wrapper_socket" show-options -gv @noctalia_surface)" == "#333333" ]]
grep -q 'noctalia.conf' "$test_config/tmux/tmux.conf"

HOME="$test_home" XDG_CONFIG_HOME="$test_config" bash "$tmux_dir/undo.sh" >/dev/null
! grep -q 'noctalia.conf' "$test_config/tmux/tmux.conf"
[ ! -e "$test_theme" ]

# Undo must be idempotent.
HOME="$test_home" XDG_CONFIG_HOME="$test_config" bash "$tmux_dir/undo.sh" >/dev/null
