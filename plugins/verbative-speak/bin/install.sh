#!/usr/bin/env bash
# Verbative for Claude Code: the one-time setup, started in the background by the
# first session. Downloads the hooks, the voice engine and the voice model (each
# SHA-256 pinned, from Verbative's release page; the model unless the VS Code
# extension already has one), then marks the plugin ready. Safe to rerun: finished
# steps are skipped, and only one setup runs at a time.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$HERE/lib.sh"
. "$HERE/pins.sh"

[ -z "$VB_UNSUPPORTED" ] || exit 0
mkdir -p "$VB_DIR/bin"
exec >> "$VB_DIR/install.log" 2>> "$VB_DIR/install.log"

LOCK="$VB_DIR/install.lock"
if ! mkdir "$LOCK" 2> /dev/null; then
  pid="$(cat "$LOCK/pid" 2> /dev/null || true)"
  if [ -n "$pid" ]; then
    kill -0 "$pid" 2> /dev/null && exit 0
  elif [ -z "$(find "$LOCK" -maxdepth 0 -mmin +10 2> /dev/null)" ]; then
    exit 0 # just taken, its pid not written yet
  fi
  rm -rf "$LOCK" && mkdir "$LOCK" || exit 0
fi
echo $$ > "$LOCK/pid"
trap 'rm -rf "$LOCK"' EXIT

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
fail() {
  log "FAILED: $*"
  echo "$*" > "$VB_DIR/install-error"
  exit 1
}

# fetch URL DEST SHA — download with resume and retries, then verify. Nothing is
# installed without its pinned checksum.
fetch() {
  local url="$1" dest="$2" sha="$3"
  [ -n "$sha" ] || fail "$(basename "$dest") has no checksum in this plugin version."
  mkdir -p "$(dirname "$dest")"
  if [ -f "$dest" ] && [ "$(vb_sha256 "$dest")" = "$sha" ]; then return 0; fi
  # HTTPS only (redirects too); a download stuck under 1 KB/s for a minute gives up.
  local opts=(-fsSL --proto =https --proto-redir =https --retry 5 --retry-delay 3
    --connect-timeout 20 --speed-limit 1024 --speed-time 60)
  curl "${opts[@]}" -C - -o "$dest.part" "$url" \
    || curl "${opts[@]}" -o "$dest.part" "$url" \
    || fail "Couldn't download $(basename "$dest"). Check the connection; setup retries in the next session."
  if [ "$(vb_sha256 "$dest.part")" != "$sha" ]; then
    rm -f "$dest.part"
    fail "$(basename "$dest") didn't match its checksum, so it wasn't installed."
  fi
  mv -f "$dest.part" "$dest"
}

# install_bin ID TAG SHA — one release archive into its own folder,
# plugin/bin/<id>-<tag>/<id>/. The marker (.<id>.version, which lib.sh reads) is
# written last, so a half-done update keeps using the old one. Old folders go when
# they can: on Windows a running engine keeps its files locked until it exits.
install_bin() {
  local id="$1" tag="$2" sha="$3"
  local marker="$VB_DIR/bin/.$id.version" dest="$VB_DIR/bin/$id-$tag"
  local exe="$dest/$id/$id$VB_EXE"
  if [ "$(cat "$marker" 2> /dev/null)" = "$tag" ] && [ -x "$exe" ]; then return 0; fi
  [ -n "$sha" ] || fail "This plugin version has no $id build for $VB_PLAT yet."
  # Named by version, so a download an older version left half-done is never resumed.
  local archive="$VB_DIR/downloads/$id-$tag-$VB_PLAT.tar.gz"
  fetch "$VB_RELEASES/$tag/$id-$VB_PLAT.tar.gz" "$archive" "$sha"
  local stage="$VB_DIR/bin/.stage-$id"
  rm -rf "$stage" && mkdir -p "$stage" || fail "Couldn't prepare $id."
  tar --no-same-owner -xzf "$archive" -C "$stage" || fail "Couldn't unpack $id."
  [ -d "$stage/$id" ] || fail "The $id archive has an unexpected layout."
  rm -rf "$dest" && mkdir -p "$dest" && mv "$stage/$id" "$dest/$id" || fail "Couldn't install $id."
  [ -x "$exe" ] || fail "The $id archive has no $id program."
  rm -rf "$stage" "$VB_DIR/downloads/$id-"*
  echo "$tag" > "$marker"
  local old
  for old in "$VB_DIR/bin/$id" "$VB_DIR/bin/$id"-*; do
    [ "$old" = "$dest" ] || rm -rf "$old" 2> /dev/null || true
  done
  log "installed $id ($tag)"
}

log "setup started (plugin $VB_PLUGIN_VERSION, $VB_PLAT)"
rm -f "$VB_DIR/install-error"
# This platform's pinned checksums, named outright (no variable looked up by a name
# built at run time).
case "$VB_PLAT" in
  darwin-arm64) hooks_sha="$VB_HOOKS_SHA_darwin_arm64" tts_sha="$VB_TTS_SHA_darwin_arm64" ;;
  win32-x64) hooks_sha="$VB_HOOKS_SHA_win32_x64" tts_sha="$VB_TTS_SHA_win32_x64" ;;
  *) hooks_sha="" tts_sha="" ;;
esac
install_bin verbative-hooks "$VB_HOOKS_TAG" "$hooks_sha"
install_bin verbative-tts "$VB_TTS_TAG" "$tts_sha"
VB_HOOKS="$(vb_bin verbative-hooks)"

if vb_extension_model; then
  rm -f "$VB_DIR/storage-dir"
  log "using the VS Code extension's voice model"
else
  store="$VB_DIR/storage"
  if [ "$VB_PLAT" = "darwin-arm64" ]; then
    fetch "$VB_RELEASES/$VB_MODEL_TAG/config.json" "$store/kokoro-mlx/config.json" "$VB_MLX_CONFIG_SHA"
    fetch "$VB_RELEASES/$VB_MODEL_TAG/kokoro-v1_0.safetensors" "$store/kokoro-mlx/kokoro-v1_0.safetensors" "$VB_MLX_MODEL_SHA"
    while read -r voice sha; do
      [ -n "$voice" ] || continue
      fetch "$VB_RELEASES/$VB_MODEL_TAG/$voice.safetensors" "$store/kokoro-mlx/voices/$voice.safetensors" "$sha"
    done <<< "$VB_MLX_VOICES"
  else
    fetch "$VB_RELEASES/$VB_MODEL_TAG/kokoro-v1.0.onnx" "$store/kokoro-onnx/kokoro-v1.0.onnx" "$VB_ONNX_MODEL_SHA"
    fetch "$VB_RELEASES/$VB_MODEL_TAG/voices-v1.0.bin" "$store/kokoro-onnx/voices-v1.0.bin" "$VB_ONNX_VOICES_SHA"
  fi
  vb_native_path "$store" > "$VB_DIR/storage-dir"
  log "voice model ready"
fi

: > "$VB_DIR/ready"
log "setup finished"
VERBATIVE_PLUGIN=1 "$VB_HOOKS" __plugin sync "$VB_PLUGIN_VERSION" < /dev/null > /dev/null 2> /dev/null || true
