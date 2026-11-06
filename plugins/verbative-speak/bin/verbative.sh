#!/usr/bin/env bash
# Verbative for Claude Code: the one entry point hooks.json and the commands call.
#   verbative hook <name>      a Claude Code hook (its JSON payload on stdin)
#   verbative session-start    SessionStart: start or finish the setup, refresh the plan
#   verbative cmd [args...]    the /verbative-speak:* commands (status, set, on, off, test,
#                              account [login, verify, logout])
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/lib.sh"
. "$HERE/pins.sh"

# The hooks binary in plugin mode, with this plugin's engine and, when the plugin
# downloaded it, its voice model.
run() {
  export VERBATIVE_PLUGIN=1
  export VERBATIVE_PLUGIN_BIN="$HERE/verbative.sh" # /verbative-speak:voice saves settings through it
  VERBATIVE_TTS_BIN="$(vb_native_path "$VB_TTS")"
  export VERBATIVE_TTS_BIN
  if [ -f "$VB_DIR/storage-dir" ]; then
    VERBATIVE_STORAGE="$(cat "$VB_DIR/storage-dir")"
    export VERBATIVE_STORAGE
  fi
  exec "$VB_HOOKS" "$@"
}

# A line the user sees on screen (not added to Claude's context).
# Our own messages only: no quotes or backslashes to escape. One echo prints the whole
# answer; nothing else in this script writes to its output.
tell_user() {
  echo "{\"systemMessage\": \"$1\"}"
}

# UserPromptSubmit. What Claude is told comes word for word from this plugin's own text
# files in instructions/ (one line each, no quotes or backslashes: tests/install.test.sh
# checks); the hooks program only decides which one applies now, and its output never
# reaches Claude. Voice on: the spoken-summary line, on every prompt. Just switched off:
# once per session, the note to drop that line. Today's free summaries used up: the line
# stays (it's still the reply's summary), and the user sees one note.
instruct() {
  local said file="" note="" text=""
  said="$(run "$@")"
  case "$said" in
    *"Voice output is OFF"*) file="voice-off.txt" ;;
    *"[Verbative voice]"*) file="spoken-summary.txt" ;;
  esac
  case "$said" in
    *'"systemMessage"'*) note="Verbative: today's 10 free spoken summaries are used up, so it stays quiet until 00:00 UTC. For unlimited, run /verbative-speak:account to upgrade to Code Advanced (14-day free trial): https://verbative.de/pricing/" ;;
  esac
  [ -n "$file" ] && text="$(tr -d '\r' < "$HERE/../instructions/$file")"
  if [ -n "$note" ] && [ -n "$text" ]; then
    echo "{\"systemMessage\": \"$note\", \"hookSpecificOutput\": {\"hookEventName\": \"UserPromptSubmit\", \"additionalContext\": \"$text\"}}"
  elif [ -n "$note" ]; then
    tell_user "$note"
  elif [ -n "$text" ]; then
    printf '%s' "$text"
  fi
}

start_setup() {
  nohup bash "$HERE/install.sh" < /dev/null > /dev/null 2> /dev/null &
}

outdated() {
  [ "$(cat "$VB_DIR/bin/.verbative-hooks.version" 2> /dev/null)" != "$VB_HOOKS_TAG" ] \
    || [ "$(cat "$VB_DIR/bin/.verbative-tts.version" 2> /dev/null)" != "$VB_TTS_TAG" ]
}

case "${1:-}" in
  hook)
    shift
    if [ -n "$VB_UNSUPPORTED" ] || [ ! -x "$VB_HOOKS" ]; then
      cat > /dev/null
      exit 0
    fi
    if [ "${1:-}" = "voice-instruction" ]; then
      instruct "$@"
      exit 0
    fi
    run "$@"
    ;;
  session-start)
    cat > /dev/null
    # 0.3.0 put Verbative's hooks into the user's own Claude Code settings (through
    # /verbative-speak:setup). From 0.3.1 they're the plugin's again, so that copy comes
    # out, or every hook would run twice. The hooks program takes out only those entries
    # and keeps the previous file as settings.json.verbative-backup.
    moved=""
    if [ -f "$VB_DIR/verbative-speak-hook.sh" ] && [ -x "$VB_HOOKS" ] \
      && (VERBATIVE_PLUGIN=1 "$VB_HOOKS" __plugin settings-hooks remove < /dev/null > /dev/null 2> /dev/null); then
      rm -f "$VB_DIR/verbative-speak-hook.sh" "$VB_DIR/plugin-root"
      moved=1
    fi
    if [ -n "$VB_UNSUPPORTED" ]; then
      # Claude's Cowork mode may run where no sound can play: no message there,
      # it would only confuse. Where it can play sound, Cowork sets up like any session.
      [ "${CLAUDE_CODE_ENTRYPOINT:-}" = "local-agent" ] && exit 0
      [ -f "$VB_DIR/unsupported-told" ] && exit 0
      mkdir -p "$VB_DIR" && : > "$VB_DIR/unsupported-told"
      tell_user "$VB_UNSUPPORTED"
      exit 0
    fi
    # Ready, but something it needs is gone (a binary, or the VS Code extension's
    # voice model after the extension was removed): set up again rather than go quiet.
    if [ -f "$VB_DIR/ready" ] && { [ ! -x "$VB_HOOKS" ] || [ ! -x "$VB_TTS" ] \
      || { [ ! -f "$VB_DIR/storage-dir" ] && ! vb_extension_model; }; }; then
      rm -f "$VB_DIR/ready"
    fi
    if [ ! -f "$VB_DIR/ready" ]; then
      if [ -f "$VB_DIR/install-error" ]; then
        tell_user "Verbative's voice setup stopped last time ($(tr -d '"\\' < "$VB_DIR/install-error")). It is trying again now."
      else
        tell_user "Verbative is downloading its voice (about half a gigabyte, one time). Claude starts speaking as soon as it's ready."
      fi
      start_setup
      exit 0
    fi
    # Ready. A plugin update brings new binaries: fetch them quietly, the old ones
    # keep working meanwhile. Then refresh the plan (free or Code Advanced).
    if outdated; then start_setup; fi
    (VERBATIVE_PLUGIN=1 "$VB_HOOKS" __plugin sync "$VB_PLUGIN_VERSION" < /dev/null > /dev/null 2> /dev/null &)
    if [ -n "$moved" ]; then
      tell_user "Verbative's hooks are part of the plugin again, so the copies setup added to your Claude Code settings were taken out (the previous file is saved as settings.json.verbative-backup)."
    fi
    exit 0
    ;;
  cmd)
    # The /verbative-speak:* commands. Always exit 0: a failing command makes Claude Code drop
    # the whole output, and the output is what says what happened.
    shift
    if [ -n "$VB_UNSUPPORTED" ]; then
      echo "$VB_UNSUPPORTED"
      exit 0
    fi
    if [ ! -x "$VB_HOOKS" ]; then
      echo "Verbative is still setting up its voice. Progress: $VB_DIR/install.log"
      exit 0
    fi
    if outdated && [ "$(cat "$VB_DIR/bin/.verbative-hooks.version" 2> /dev/null)" != "$VB_HOOKS_TAG" ]; then
      echo "Verbative is updating to this plugin version; try again in a minute."
      exit 0
    fi
    # Hooks program v17 also reports on the hooks 0.3.0's setup added to the settings;
    # this version registers them in the plugin, so that line doesn't apply.
    (run __plugin "$@") | sed '/^Hooks: /d'
    exit 0
    ;;
  *)
    echo "usage: verbative hook <name> | session-start | cmd [args...]" >&2
    exit 2
    ;;
esac
