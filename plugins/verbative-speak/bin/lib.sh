# Verbative for Claude Code: shared paths. Sourced by bin/verbative.sh and bin/install.sh.
#
# Runs in bash on macOS and in the Git Bash Claude Code uses on Windows. Everything
# lands in Verbative's data folder (the same one the VS Code extension uses), under
# plugin/, so the plugin never touches the extension's own binaries.

VB_PLUGIN_VERSION="0.3.0"
VB_UNSUPPORTED=""

case "$(uname -s)" in
  Darwin)
    VB_PLAT="darwin-arm64"
    VB_EXE=""
    VB_ROOT="$HOME/Library/Application Support/Verbative"
    if [ "$(uname -m)" != "arm64" ]; then
      VB_UNSUPPORTED="Verbative's voice needs a Mac with Apple Silicon (or Windows)."
    fi
    ;;
  MINGW* | MSYS* | CYGWIN*)
    VB_PLAT="win32-x64"
    VB_EXE=".exe"
    VB_ROOT="$(cygpath -u "${APPDATA:-$USERPROFILE/AppData/Roaming}")/Verbative"
    ;;
  *)
    VB_PLAT=""
    VB_EXE=""
    VB_ROOT="${XDG_DATA_HOME:-$HOME/.local/share}/verbative"
    VB_UNSUPPORTED="Verbative's voice runs on macOS (Apple Silicon) and Windows; Linux isn't supported yet."
    ;;
esac
# Tests point the whole thing at a sandbox; the hooks binary honours the same variable.
# (A project's own settings could set it too, but only for that project's sessions,
# which its settings can already give hooks of their own: nothing is left behind.)
if [ -n "${VERBATIVE_DATA_DIR:-}" ]; then VB_ROOT="$VERBATIVE_DATA_DIR"; fi

VB_DIR="$VB_ROOT/plugin"
# What the hooks in the user's Claude Code settings run (bin/settings-hook.sh, copied
# here by /verbative-speak:setup): the same path across plugin updates.
VB_LAUNCHER="$VB_DIR/verbative-speak-hook.sh"

# The installed program for ID: in the folder of the version its marker names
# (install.sh), or where versions before that kept it.
vb_bin() {
  local id="$1" tag
  tag="$(cat "$VB_DIR/bin/.$id.version" 2> /dev/null)"
  if [ -n "$tag" ] && [ -x "$VB_DIR/bin/$id-$tag/$id/$id$VB_EXE" ]; then
    echo "$VB_DIR/bin/$id-$tag/$id/$id$VB_EXE"
  else
    echo "$VB_DIR/bin/$id/$id$VB_EXE"
  fi
}
VB_HOOKS="$(vb_bin verbative-hooks)"
VB_TTS="$(vb_bin verbative-tts)"

# The native Windows binaries need Windows paths in their environment.
vb_native_path() {
  if command -v cygpath > /dev/null; then cygpath -w "$1"; else echo "$1"; fi
}

# A path written into Claude Code's settings: on Windows with forward slashes
# (C:/Users/...), which both Git Bash and Windows read.
vb_settings_path() {
  if command -v cygpath > /dev/null; then cygpath -m "$1"; else echo "$1"; fi
}

vb_sha256() {
  if command -v shasum > /dev/null; then
    shasum -a 256 "$1" | cut -d' ' -f1
  else
    sha256sum "$1" | cut -d' ' -f1
  fi
}

# A voice model the VS Code extension already downloaded (any of the editors it runs
# in), so the plugin doesn't fetch a second copy. The engine finds it on its own.
vb_extension_model() {
  local base ide
  case "$VB_PLAT" in
    darwin-arm64) base="$HOME/Library/Application Support" ;;
    win32-x64) base="$(cygpath -u "${APPDATA:-$USERPROFILE/AppData/Roaming}")" ;;
    *) return 1 ;;
  esac
  for ide in Code Cursor VSCodium; do
    local store="$base/$ide/User/globalStorage/verbative.verbative"
    if [ "$VB_PLAT" = "darwin-arm64" ] && [ -f "$store/kokoro-mlx/kokoro-v1_0.safetensors" ]; then return 0; fi
    if [ "$VB_PLAT" = "win32-x64" ] && [ -f "$store/kokoro-onnx/kokoro-v1.0.onnx" ]; then return 0; fi
  done
  return 1
}
