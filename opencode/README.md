# OpenCode

Generates an OpenCode theme from the Noctalia palette, including UI, syntax,
Markdown and diff colors.

The generated theme contains distinct light and dark palettes, so it follows
whichever mode OpenCode selects.

## Setup

Install OpenCode and enable **Opencode** in **Noctalia Settings -> Templates**.
The output is `$XDG_CONFIG_HOME/opencode/themes/matugen.json`. Select the custom
**matugen** theme in OpenCode.

If **matugen** is selected, the template also updates `theme.mode` in
`$XDG_CONFIG_HOME/opencode/cli.json` when Noctalia switches between light and
dark. OpenCode reloads `cli.json` live, so a running instance follows the
change without a restart. The sync uses `jq`; if `jq` is unavailable the theme
is still generated, but the mode is left untouched.

If you use a different OpenCode theme, `cli.json` is not modified.

## Undo

Disabling the template removes the generated theme file and its hidden state
file. If `matugen` is still selected, it also restores the `theme.mode` that
was active before the first sync. OpenCode may need a restart if you disable
the template while it is still using the removed `matugen` theme.

## Notes

- The generated file is replaced on palette updates, so back up any existing
  customizations there.
- Tested with OpenCode 2.2.5.
