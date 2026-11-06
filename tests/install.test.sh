#!/usr/bin/env bash
# The plugin's setup and entry point, offline, in a sandbox home (macOS): a stand-in
# curl serves fake "releases" from a local folder (each pinned by its real checksum),
# and a fake voice model sits where the VS Code extension keeps it.
# Run: bash tests/install.test.sh
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d /tmp/vb-plugin-test-XXXX)"
trap 'rm -rf "$T"' EXIT
export HOME="$T/home"
unset VERBATIVE_DATA_DIR CLAUDE_PLUGIN_ROOT
cp -R "$REPO/plugins/verbative-speak" "$T/plugin"
P="$T/plugin/bin"
pass=0
ok() { pass=$((pass + 1)); echo "  ok - $1"; }
no() { echo "  FAIL - $1"; exit 1; }

# The stand-in curl: serves https://<path> from $SRV/<path>, else fails like a 404.
export SRV="$T/srv"
mkdir -p "$T/fakebin" "$SRV"
cat > "$T/fakebin/curl" << 'EOF'
#!/bin/sh
out="" url=""
while [ $# -gt 0 ]; do
  case "$1" in
    -o) out="$2"; shift ;;
    https://*) url="$1" ;;
  esac
  shift
done
[ -f "$SRV/${url#https://}" ] || exit 22
cp "$SRV/${url#https://}" "$out"
EOF
chmod +x "$T/fakebin/curl"
export PATH="$T/fakebin:$PATH"

# A fake binary: answers __plugin with its version, every hook with nothing.
fake_archive() { # id tag
  local d="$T/build/$1-$2" && mkdir -p "$d/$1"
  printf '#!/bin/sh\necho "%s %s $*"\n' "$1" "$2" > "$d/$1/$1" && chmod +x "$d/$1/$1"
  tar -czf "$T/$1-$2.tar.gz" -C "$d" "$1"
  shasum -a 256 "$T/$1-$2.tar.gz" | cut -d' ' -f1
}
pin() { # tag-var tag sha-var sha
  sed -i '' -e "s|^$1=.*|$1=\"$2\"|" -e "s|^$3=.*|$3=\"$4\"|" "$P/pins.sh"
}
publish() { # id tag [file]: put a release where the stand-in curl finds it
  local d="$SRV/github.com/verbative/verbative-dist/releases/download/$2"
  mkdir -p "$d" && cp "${3:-$T/$1-$2.tar.gz}" "$d/$1-darwin-arm64.tar.gz"
}
mkdir -p "$HOME/Library/Application Support/Code/User/globalStorage/verbative.verbative/kokoro-mlx"
: > "$HOME/Library/Application Support/Code/User/globalStorage/verbative.verbative/kokoro-mlx/kokoro-v1_0.safetensors"
D="$HOME/Library/Application Support/Verbative/plugin"

pin VB_HOOKS_TAG verbative-hooks-v12 VB_HOOKS_SHA_darwin_arm64 "$(fake_archive verbative-hooks verbative-hooks-v12)"
pin VB_TTS_TAG verbative-tts-v7 VB_TTS_SHA_darwin_arm64 "$(fake_archive verbative-tts verbative-tts-v7)"
publish verbative-hooks verbative-hooks-v12 && publish verbative-tts verbative-tts-v7
bash "$P/install.sh" || no "install ran"
[ -f "$D/ready" ] && ok "setup finishes (the extension's model is reused)" || no "ready: $(cat "$D/install.log")"
[ -x "$D/bin/verbative-hooks-verbative-hooks-v12/verbative-hooks/verbative-hooks" ] \
  && [ "$(cat "$D/bin/.verbative-hooks.version")" = verbative-hooks-v12 ] \
  && [ -z "$(ls -A "$D/downloads")" ] \
  && ok "each version in its own folder, its marker written, no download left over" || no "layout"
out="$(bash "$P/verbative.sh" cmd status)"
[ "$out" = "verbative-hooks verbative-hooks-v12 __plugin status" ] && ok "commands run the installed version" || no "cmd: $out"

pin VB_HOOKS_TAG verbative-hooks-v13 VB_HOOKS_SHA_darwin_arm64 "$(fake_archive verbative-hooks verbative-hooks-v13)"
out="$(bash "$P/verbative.sh" cmd status)"; rc=$?
[ $rc = 0 ] && [[ "$out" == *"updating"* ]] && ok "during an update, a command says so (and exits 0)" || no "updating: $rc $out"
publish verbative-hooks verbative-hooks-v13
printf 'half of an older download' > "$D/downloads/verbative-hooks-verbative-hooks-v12-darwin-arm64.tar.gz.part"
bash "$P/install.sh" || no "update ran"
[ -x "$D/bin/verbative-hooks-verbative-hooks-v13/verbative-hooks/verbative-hooks" ] \
  && [ ! -e "$D/bin/verbative-hooks-verbative-hooks-v12" ] \
  && [ -z "$(ls -A "$D/downloads")" ] \
  && [ "$(bash "$P/verbative.sh" cmd status)" = "verbative-hooks verbative-hooks-v13 __plugin status" ] \
  && ok "an update installs beside the old version, then removes it and old downloads" || no "update layout"

printf 'nonsense' > "$T/bad.tar.gz"
pin VB_HOOKS_TAG verbative-hooks-v14 VB_HOOKS_SHA_darwin_arm64 "$(fake_archive verbative-hooks verbative-hooks-v14)"
publish verbative-hooks verbative-hooks-v14 "$T/bad.tar.gz"
bash "$P/install.sh"
[[ "$(cat "$D/install-error" 2> /dev/null)" == *"didn't match its checksum"* ]] \
  && [ "$(cat "$D/bin/.verbative-hooks.version")" = verbative-hooks-v13 ] \
  && [ ! -e "$D/bin/verbative-hooks-verbative-hooks-v14" ] \
  && ok "a download that doesn't match its checksum changes nothing" || no "checksum: $(tail -1 "$D/install.log")"

pin VB_HOOKS_TAG verbative-hooks-v15 VB_HOOKS_SHA_darwin_arm64 ""
bash "$P/install.sh"
[[ "$(cat "$D/install-error" 2> /dev/null)" == *"no verbative-hooks build"* ]] \
  && [ "$(cat "$D/bin/.verbative-hooks.version")" = verbative-hooks-v13 ] \
  && ok "a version without a pinned build for this platform installs nothing" || no "unpinned: $(tail -1 "$D/install.log")"
pin VB_HOOKS_TAG verbative-hooks-v13 VB_HOOKS_SHA_darwin_arm64 x

rm -rf "$D/bin/verbative-tts-verbative-tts-v7"
echo '{}' | bash "$P/verbative.sh" session-start > /dev/null
[ ! -f "$D/ready" ] && ok "a binary gone missing: setup runs again instead of going quiet" || no "re-setup"
for _ in $(seq 1 50); do [ -f "$D/ready" ] && break; sleep 0.2; done
[ -f "$D/ready" ] && [ -x "$D/bin/verbative-tts-verbative-tts-v7/verbative-tts/verbative-tts" ] \
  && ok "…and is ready again" || no "re-setup finished: $(tail -2 "$D/install.log")"
out="$(bash "$P/verbative.sh" cmd whatever)"; [ $? = 0 ] && ok "an unknown word still exits 0" || no "exit code"

# /verbative-speak:setup: the hooks go into the user's own settings, each running a
# launcher in the data folder that hands it to the installed plugin.
L="$D/verbative-speak-hook.sh"
said="verbative-hooks verbative-hooks-v13 __plugin settings-hooks"
out="$(bash "$P/verbative.sh" setup)"
[ "$out" = "$said preview $L" ] && [ ! -e "$L" ] \
  && ok "setup on its own only previews (the hooks program reads the settings)" || no "preview: $out"
out="$(bash "$P/verbative.sh" setup install)"
[ "$out" = "$said install $L" ] && cmp -s "$P/settings-hook.sh" "$L" && [ "$(cat "$D/plugin-root")" = "$T/plugin" ] \
  && ok "install puts the launcher in place and records the plugin folder, then has the hooks added" || no "install: $out"
hook() { bash "$L" "$@" < /dev/null; }
CFG="$HOME/.claude"
mkdir -p "$CFG/plugins"
[ "$(hook hook speak-summary)" = "verbative-hooks verbative-hooks-v13 speak-summary" ] \
  && ok "a plugin folder loaded with --plugin-dir: the launcher hands each hook to it" || no "launcher, plugin folder"
mkdir -p "$T/installed/bin" && printf '#!/bin/sh\necho "installed copy $*"\n' > "$T/installed/bin/verbative.sh"
cat > "$CFG/plugins/installed_plugins.json" << EOF
{
  "version": 2,
  "plugins": {
    "verbative-speak@verbative": [
      {
        "scope": "user",
        "installPath": "$T/installed",
        "version": "0.3.0"
      }
    ],
    "other@elsewhere": [
      {
        "scope": "user",
        "installPath": "/nowhere"
      }
    ]
  }
}
EOF
[ "$(hook hook speak-summary)" = "installed copy hook speak-summary" ] \
  && ok "installed from a marketplace: it follows Claude Code's list of installed plugins" || no "launcher, installed: $(hook hook speak-summary)"
echo '{"enabledPlugins": {"verbative-speak@verbative": false}}' > "$CFG/settings.json"
[ -z "$(hook hook speak-summary)" ] && ok "switched off in /plugin: nothing runs" || no "launcher, disabled"
rm "$CFG/settings.json"
stale="$CFG/plugins/cache/verbative/verbative-speak/0.2.0"
mkdir -p "$stale/bin" && printf '#!/bin/sh\necho stale\n' > "$stale/bin/verbative.sh"
echo '{"version": 2, "plugins": {}}' > "$CFG/plugins/installed_plugins.json"
echo "$stale" > "$D/plugin-root"
[ -z "$(hook hook speak-summary)" ] && ok "uninstalled: nothing runs, even with an old copy left in the plugin cache" || no "launcher, uninstalled"
echo "# an older launcher" > "$L"
bash "$P/verbative.sh" session-start < /dev/null > /dev/null
cmp -s "$P/settings-hook.sh" "$L" && ok "a session start brings the launcher up to date" || no "launcher refresh"
out="$(bash "$P/verbative.sh" setup remove)"
[ "$out" = "$said remove $L" ] && [ ! -e "$L" ] && [ ! -e "$D/plugin-root" ] \
  && ok "remove has the hooks taken out, and the launcher goes too" || no "remove: $out"

# What Claude is told: only this plugin's own text files, whatever the program says.
I="$T/plugin/instructions"
for f in "$I"/*.txt; do
  [ "$(wc -l < "$f")" -eq 1 ] && ! grep -q '["\\]' "$f" || no "$(basename "$f") isn't one line without quotes or backslashes"
done
ok "each instruction is one plain line"
H="$D/bin/verbative-hooks-verbative-hooks-v13/verbative-hooks/verbative-hooks"
printf '#!/bin/sh\ncat > /dev/null\nprintf "%%s" "$FAKE_SAID"\n' > "$H" && chmod +x "$H"
said() { FAKE_SAID="$1" bash "$P/verbative.sh" hook voice-instruction < /dev/null; }
[ "$(said '[Verbative voice] whatever the program says')" = "$(cat "$I/spoken-summary.txt")" ] \
  && ok "voice on: Claude is told instructions/spoken-summary.txt, word for word" || no "voice on"
[ "$(said '[Verbative voice] Voice output is OFF. whatever')" = "$(cat "$I/voice-off.txt")" ] \
  && ok "voice just switched off: instructions/voice-off.txt" || no "voice off"
[ -z "$(said '')" ] && [ -z "$(said 'anything else')" ] \
  && ok "otherwise nothing: the program's own words never reach Claude" || no "nothing"
out="$(said '{"systemMessage": "x", "hookSpecificOutput": {"additionalContext": "[Verbative voice] y"}}')"
python3 -c 'import json,sys; o=json.loads(sys.argv[1]); assert o["hookSpecificOutput"]["additionalContext"]==open(sys.argv[2],encoding="utf-8").read().rstrip("\n") and "used up" in o["systemMessage"]' "$out" "$I/spoken-summary.txt" \
  && ok "free summaries used up: the same line, and one note on screen" || no "used up: $out"

# A setup preview, read back by Claude, must never pass for done.
note="Nothing has been changed yet: this only shows what setup would do."
out="$(FAKE_SAID="This adds 8 hooks to your Claude Code settings." bash "$P/verbative.sh" setup preview < /dev/null)"
[ "$(printf '%s\n' "$out" | tail -1)" = "$note" ] && ok "a setup preview ends by saying nothing has changed yet" || no "preview note: $out"
out="$(FAKE_SAID="There are no Verbative hooks in your Claude Code settings." bash "$P/verbative.sh" setup preview-remove < /dev/null)"
[[ "$out" != *"$note"* ]] && ok "…and only when it shows a change" || no "preview note, nothing to remove: $out"

# Without the extension's voice model, setup fetches it from Verbative's releases.
rm -rf "$HOME/Library/Application Support/Code/User/globalStorage/verbative.verbative" "$D/ready"
M="$SRV/github.com/verbative/verbative-dist/releases/download/$(. "$P/pins.sh" && echo "$VB_MODEL_TAG")"
mkdir -p "$M"
for f in config.json kokoro-v1_0.safetensors af_heart.safetensors; do printf 'fake %s' "$f" > "$M/$f"; done
sum() { shasum -a 256 "$M/$1" | cut -d' ' -f1; }
cat >> "$P/pins.sh" << EOF
VB_MLX_CONFIG_SHA="$(sum config.json)"
VB_MLX_MODEL_SHA="$(sum kokoro-v1_0.safetensors)"
VB_MLX_VOICES="af_heart $(sum af_heart.safetensors)"
EOF
bash "$P/install.sh"
[ -f "$D/ready" ] && cmp -s "$M/af_heart.safetensors" "$D/storage/kokoro-mlx/voices/af_heart.safetensors" \
  && [ "$(cat "$D/storage-dir")" = "$D/storage" ] \
  && ok "without the extension's model, setup fetches it from Verbative's releases" || no "model: $(tail -2 "$D/install.log")"

# /verbative-speak:setup with an older hooks program, or none that downloads.
pin VB_HOOKS_TAG verbative-hooks-v18 VB_HOOKS_SHA_darwin_arm64 "$(fake_archive verbative-hooks verbative-hooks-v18)"
publish verbative-hooks verbative-hooks-v18
out="$(bash "$P/verbative.sh" setup)"
[ "$out" = "verbative-hooks verbative-hooks-v18 __plugin settings-hooks preview $D/verbative-speak-hook.sh" ] \
  && [ "$(cat "$D/bin/.verbative-tts.version")" = verbative-tts-v7 ] \
  && ok "setup fetches this version's hooks program first (only that), then previews with it" || no "setup update: $out"
pin VB_HOOKS_TAG verbative-hooks-v19 VB_HOOKS_SHA_darwin_arm64 "$(fake_archive verbative-hooks verbative-hooks-v19)"
start=$SECONDS
out="$(bash "$P/verbative.sh" setup)"; rc=$?
[ $rc = 0 ] && [[ "$out" == *"couldn't download its hooks program"* ]] && [ $((SECONDS - start)) -lt 10 ] \
  && ok "a hooks program that won't download: setup says so right away (and exits 0)" || no "setup offline: $rc $out"
echo "install: $pass checks passed"
