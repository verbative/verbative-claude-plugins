#!/usr/bin/env bash
# Verbative for Claude Code: what the hooks in your Claude Code settings run.
#
# /verbative-speak:setup copies this file to Verbative's data folder (as
# verbative-speak-hook.sh, a path that stays the same across plugin updates) and adds
# hooks that run it to your settings, after showing them to you. It hands each one to
# the plugin as Claude Code has it installed now (bin/verbative.sh), so an update needs
# no new setup. With the plugin switched off or uninstalled it does nothing;
# /verbative-speak:setup remove takes the hooks out of your settings again.
set -u
cfg="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
quiet() {
  cat > /dev/null
  exit 0
}

# Switched off in /plugin.
grep -qE '"verbative-speak@[^"]*"[[:space:]]*:[[:space:]]*false' "$cfg/settings.json" 2> /dev/null && quiet

# Where Claude Code installed it, from its list of installed plugins (Windows paths
# come with escaped backslashes; Git Bash reads them with forward slashes).
root="$(tr -d '\r\n' 2> /dev/null < "$cfg/plugins/installed_plugins.json" \
  | sed -n 's/.*"verbative-speak@[^"]*"[^]]*"installPath"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | sed 's#\\\\#/#g')"
# Not installed from a marketplace: a plugin folder loaded with --plugin-dir, as setup
# recorded it. A copy in Claude Code's plugin cache doesn't count: that one is left
# behind when the plugin is uninstalled.
if [ -z "$root" ]; then
  root="$(cat "$(dirname "$0")/plugin-root" 2> /dev/null)"
  case "$root" in */plugins/cache/*) root="" ;; esac
fi
[ -n "$root" ] && [ -f "$root/bin/verbative.sh" ] || quiet
exec bash "$root/bin/verbative.sh" "$@"
