![tmux dark and light Material themes](screenshot.png)

## What this template does

Generates `$XDG_CONFIG_HOME/tmux/themes/noctalia.conf` from the active Noctalia
palette and adds a `source-file` line for it to your tmux config. The template
re-applies the file and updates running tmux servers on every theme change.

It also exposes the terminal palette through tmux so applications can query it:

- `window-style` / `window-active-style` provide the background and foreground
  colors (OSC 10/11).
- `pane-colours[0..15]` provide the 16 ANSI colors (OSC 4).

This lets color-scheme-aware TUIs pick up the current Noctalia theme.

## Setup

Enable **tmux** in **Noctalia Settings → Templates**. No manual step is needed;
the apply hook finds `~/.tmux.conf` or `$XDG_CONFIG_HOME/tmux/tmux.conf` and
adds the Noctalia source line. Existing running servers are updated in place.

If your tmux config is loaded through a wrapper (for example an oh-my-zsh
`tmux.extra.conf`), the user config is still the one that gets the source line;
the running server is updated directly as well.

## Options

Inactive tabs use their own background by default. To make them inherit the
status bar background, add this before the Noctalia `source-file` line in your
tmux config:

```tmux
set -g @noctalia_inactive_tabs_use_background off
```

The explicit window background can interfere with transparent panes or a pane
background image. Add this before the Noctalia `source-file` line to leave
`window-style` / `window-active-style` at their defaults:

```tmux
set -g @noctalia_window_style off
```

## Undo

Disabling the template removes the Noctalia `source-file` line and the generated
theme file. Running servers keep the styles loaded in memory until tmux is
restarted or the config is reloaded; the hook does not try to guess a previous
theme.

## Notes

- Tested with tmux 3.8.
- `pane-colours` requires a tmux version that provides the array option.
- The generated file is rewritten on palette and theme-mode changes; keep
  custom changes elsewhere.
