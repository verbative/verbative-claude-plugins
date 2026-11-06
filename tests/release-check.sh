#!/usr/bin/env bash
# Is this repo ready to publish? Checks the manifests, that every program has a pinned
# build for each platform, and that each pin (programs and voice model) matches the file
# on Verbative's release page (GitHub's own SHA-256 of the upload; needs the network, no
# download).
# Run: bash tests/release-check.sh   (exit 0 = ready)
set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO" || exit 1
. plugins/verbative-speak/bin/pins.sh
. plugins/verbative-speak/bin/lib.sh
bad=0
ok() { echo "  ok - $1"; }
no() { echo "  NOT READY - $1"; bad=$((bad + 1)); }

manifest_version="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["version"])' plugins/verbative-speak/.claude-plugin/plugin.json)"
[ "$manifest_version" = "$VB_PLUGIN_VERSION" ] && ok "version $VB_PLUGIN_VERSION in plugin.json and lib.sh" \
  || no "plugin.json says $manifest_version, lib.sh says $VB_PLUGIN_VERSION"
if command -v claude > /dev/null 2>&1; then
  claude plugin validate . > /dev/null 2>&1 && claude plugin validate ./plugins/verbative-speak > /dev/null 2>&1 \
    && ok "Claude Code validates the marketplace and the plugin" || no "claude plugin validate fails"
fi
plain="$(python3 -c 'import json,re,sys; c=json.load(open(sys.argv[1])).get("userConfig",{}); print(" ".join(f"{k}:{o}" for k,v in c.items() for o in v.get("options",[]) if not re.fullmatch(r"[A-Za-z0-9.,:=/@+_-]+", str(o))))' plugins/verbative-speak/.claude-plugin/plugin.json)"
[ -z "$plain" ] && ok "every settings choice is a plain word" || no "settings choices that aren't plain words: $plain"
cmp -s README.md plugins/verbative-speak/README.md && ok "README copies match" || no "README.md and plugins/verbative-speak/README.md differ"
cmp -s LICENSE plugins/verbative-speak/LICENSE && ok "LICENSE copies match" || no "LICENSE and plugins/verbative-speak/LICENSE differ"
# The plugin directory refuses any line-ending rule but eol=lf (it would read other bytes
# than a checkout has).
grep -vE '^\s*(#|$)' .gitattributes | grep -E 'eol=' | grep -vqE 'eol=lf(\s|$)' && no ".gitattributes has a line-ending rule other than eol=lf"
grep -vE '^\s*(#|$)' .gitattributes | grep -qE '(^|\s)(crlf|-?binary=|!binary)' && no ".gitattributes has a crlf or binary= rule"
# The directory accepts code that runs on the user's computer (command or mcp_tool hooks,
# a local MCP server, inline shell) only from Verified organizations: the plugin ships
# none. Its hooks go into the user's own settings, through /verbative-speak:setup.
P=plugins/verbative-speak
[ ! -e "$P/hooks" ] || no "$P/hooks exists: the plugin ships no hooks (setup adds them to the user's settings)"
python3 -c 'import json,sys; m=json.load(open(sys.argv[1])); sys.exit(any(k in m for k in ("hooks","mcpServers","lspServers")))' "$P/.claude-plugin/plugin.json" \
  || no "plugin.json declares hooks or servers"
docs=("$P"/commands/*.md "$P"/skills/*/SKILL.md)
grep -lE '^hooks:' "${docs[@]}" > /dev/null && no "a command or skill declares hooks in its frontmatter"
grep -lF '!`' "${docs[@]}" > /dev/null && no "a command or skill runs inline shell"
for f in plugins/verbative-speak/bin/verbative.sh plugins/verbative-speak/bin/install.sh; do
  [ "$(git ls-files -s "$f" | cut -c1-6)" = 100755 ] || no "$f isn't executable in git"
done

# GitHub's SHA-256 of each file on a release, one "name sha" per line.
digests() {
  curl -fsSL "https://api.github.com/repos/verbative/verbative-dist/releases/tags/$1" 2> /dev/null \
    | python3 -c 'import json,sys; [print(a["name"], (a.get("digest") or "").removeprefix("sha256:")) for a in json.load(sys.stdin)["assets"]]' 2> /dev/null
}
# check DIGESTS TAG FILE SHA: the pinned file is on the release and matches its pin.
check() {
  if [ -z "$4" ]; then
    no "no pin for $2's $3"
  elif [ -z "$1" ]; then
    no "$2 isn't published (or GitHub didn't answer)"
  elif ! grep -q "^$3 " <<< "$1"; then
    no "$2 has no $3"
  elif [ "$(grep "^$3 " <<< "$1" | cut -d' ' -f2)" != "$4" ]; then
    no "$2's $3 doesn't match its pin"
  else
    ok "$2 $3 matches its pin"
  fi
}

hooks="$(digests "$VB_HOOKS_TAG")"
tts="$(digests "$VB_TTS_TAG")"
model="$(digests "$VB_MODEL_TAG")"
check "$hooks" "$VB_HOOKS_TAG" verbative-hooks-darwin-arm64.tar.gz "$VB_HOOKS_SHA_darwin_arm64"
check "$hooks" "$VB_HOOKS_TAG" verbative-hooks-win32-x64.tar.gz "$VB_HOOKS_SHA_win32_x64"
check "$tts" "$VB_TTS_TAG" verbative-tts-darwin-arm64.tar.gz "$VB_TTS_SHA_darwin_arm64"
check "$tts" "$VB_TTS_TAG" verbative-tts-win32-x64.tar.gz "$VB_TTS_SHA_win32_x64"
check "$model" "$VB_MODEL_TAG" config.json "$VB_MLX_CONFIG_SHA"
check "$model" "$VB_MODEL_TAG" kokoro-v1_0.safetensors "$VB_MLX_MODEL_SHA"
while read -r voice sha; do
  [ -z "$voice" ] || check "$model" "$VB_MODEL_TAG" "$voice.safetensors" "$sha"
done <<< "$VB_MLX_VOICES"
check "$model" "$VB_MODEL_TAG" kokoro-v1.0.onnx "$VB_ONNX_MODEL_SHA"
check "$model" "$VB_MODEL_TAG" voices-v1.0.bin "$VB_ONNX_VOICES_SHA"

[ $bad = 0 ] && echo "release: ready" || echo "release: $bad thing(s) to do"
[ $bad = 0 ]
