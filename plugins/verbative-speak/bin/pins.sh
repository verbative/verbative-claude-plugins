# Verbative for Claude Code: what bin/install.sh downloads, pinned by SHA-256.
# Everything comes from Verbative's public releases: the programs (the VS Code
# extension uses the same ones) and the voice model, mirrored unchanged from its
# upstream projects. Bump with a release, then check with tests/release-check.sh.

VB_RELEASES="https://github.com/verbative/verbative-dist/releases/download"

# verbative-hooks: the hooks with the plugin mode (VERBATIVE_PLUGIN=1); v16 and later
# answer the plugin's MCP server (__plugin-mcp).
VB_HOOKS_TAG="verbative-hooks-v17"
VB_HOOKS_SHA_darwin_arm64="9eb28fe9893c14947c67ecc624fd59bdb5f27a6a8cae712a857b891720485a1a"
VB_HOOKS_SHA_win32_x64="981ad5397a54ed9dd799ff3b750c297c864ec67a469aa7299404ac51ffb5813f"

# verbative-tts: the Kokoro voice engine (MLX on Apple Silicon, ONNX on Windows).
# v7 and later take the voice speed with each request, so the plugin's own speed
# setting applies.
VB_TTS_TAG="verbative-tts-v7"
VB_TTS_SHA_darwin_arm64="7897cbbe0dd29ac190c814892fae55e7b00085f0d3212e1c40180ff70293ca70"
VB_TTS_SHA_win32_x64="527600f025be2a641b4053c5430aa1ae9dae4eda548b854bec5bac5c5753468c"

# The voice model, Kokoro-82M v1.0 (Apache-2.0): one release holds both builds, each
# file byte-identical to its upstream source (named in the release notes).
VB_MODEL_TAG="kokoro-82m-v1.0"

# For MLX (macOS): model + one small file per voice (mlx-community/Kokoro-82M-bf16).
VB_MLX_CONFIG_SHA="5abb01e2403b072bf03d04fde160443e209d7a0dad49a423be15196b9b43c17f"
VB_MLX_MODEL_SHA="4e9ecdf03b8b6cf906070390237feda473dc13327cb8d56a43deaa374c02acd8"
VB_MLX_VOICES="
af_heart 2c1c733b0e6576c810e268d3e440c21dea4e0f0131a3ba4cfc98d7fe6136d094
af_bella 112d310468cbb3cf23404d3d0b50ad3adf017b87bf38bf9edd15f4ad572df6a3
af_sarah 4940072182542f54c1035d1daf4c1cf3136ca9baa9ac57c8e006b4befcc50be6
af_nicole 574656386022c81a029e9a72558191925f44c3de2dad2fa2e45751938557d062
af_sky 957af332330db8e9bd7f9dc449475a946cb0d7d689afef64b91007bbbf20eaa0
am_adam a4f60a3b9c20353c2604a17485ba53260502a758681a84d41e8af53cc559d929
am_michael 3940147ded35deba0bb52e8132f89b719298e0520258c34584358aa5a24da2ea
bf_emma 8878a75a6661305849eeb1d6293a7177250193616e161b4c3100636434dfe69f
bf_isabella f7b6076f025649699fcfed1a6debf13049a87afdc7aafc8c72b7d81246db6ead
bm_george a3d9b8995cbbe5536f954b6be2a0f1f312f077118ba0d4d2178fc41dc8306672
bm_lewis e1e68013c21a141efe527aaec561e1174c2f5a6951b3bcecc8396adab315b247
"

# For ONNX (Windows): model + voice pack (kokoro-onnx model-files-v1.0).
VB_ONNX_MODEL_SHA="7d5df8ecf7d4b1878015a32686053fd0eebe2bc377234608764cc0ef3636a6c5"
VB_ONNX_VOICES_SHA="bca610b8308e8d99f32e6fe4197e7ec01679264efed0cac9140fe9c29f1fbf7d"
