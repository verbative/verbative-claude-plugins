# Verbative for Claude Code

Claude Code speaks. When a task finishes you hear a short summary of what Claude did.
When it waits for you, you hear what it needs: an approval for a command or a file, an
answer to its question, or a plan to review. Step away from the screen and still know
where things stand.

- **Natural voice, on your machine.** Verbative's Kokoro voice runs locally: no API
  key, nothing sent to a speech service.
- **Written to be heard.** Claude ends each reply with a one-line summary meant for
  listening, and that's what you hear (no code, no file paths).
- **Several sessions at once.** Their voices queue instead of talking over each other.

## Install

In Claude Code:

```
/plugin marketplace add verbative/verbative-claude-plugins
/plugin install verbative-speak@verbative
```

The first session downloads the voice once, about half a gigabyte. Claude starts
speaking as soon as it's ready.

Runs on **macOS with Apple Silicon** and **Windows**. Linux isn't supported yet. The
sound plays on the machine running Claude Code, so it's for local sessions, not SSH.
Claude's Cowork mode runs in a virtual machine without sound, so Verbative stays quiet
there.
On Windows, Claude Code runs plugin hooks with Git Bash, so
[Git for Windows](https://git-scm.com/download/win) must be installed.

## Commands

| Command | |
|---|---|
| `/verbative-speak:voice` | Your status, then pick the voice, its speed, what it says when a task finishes, and approval reminders; plays a sample |
| `/verbative-speak:voice off` / `on` | Switch the voice off or on |
| `/verbative-speak:voice test` | Play a test line |
| `/verbative-speak:account` | Your plan; sign in or out, step by step |

The settings also show in Claude Code's `/config` (search "verbative").

## Plans

**Free:** 10 spoken summaries a day. Approval reminders and "On it." come with them and
don't count; after the tenth summary, Verbative is quiet until the next day (00:00 UTC).
**Code Advanced:** unlimited, together with Verbative Memory and the full VS Code
extension. See [verbative.de/pricing](https://verbative.de/pricing/) (14-day free trial
for first-time subscribers).

## Using the VS Code extension too

If the Verbative extension is installed, it voices the sessions in VS Code while its
Hands-Free panel is open, and this plugin stays quiet then, so nothing is said twice.
With the panel closed, the plugin speaks. Both share your plan and one sign-in: signing
in or out in either applies to both. The plugin uses the extension's voice choices until
you pick your own with `/verbative-speak:voice`.

## What Claude is told

While the voice is on, the plugin adds one instruction to each of your prompts, word for
word from [instructions/spoken-summary.txt](https://github.com/verbative/verbative-claude-plugins/blob/main/plugins/verbative-speak/instructions/spoken-summary.txt): end the reply with a
🔊 line written to be heard. After you switch the voice off, Claude is told once per
session to drop that line ([instructions/voice-off.txt](https://github.com/verbative/verbative-claude-plugins/blob/main/plugins/verbative-speak/instructions/voice-off.txt)). The plugin
adds nothing else to your prompts.

## Privacy

The voice runs locally: what Claude writes is turned into speech on your computer, and
neither your prompts nor the replies leave it. What the plugin does send:

- **Setup:** it downloads the voice engine, the hooks and the voice model from
  Verbative's GitHub releases (the model unless the VS Code extension already has it).
  Every file is checked against a fixed checksum.
- **Your plan:** at first start it registers an anonymous license with Verbative (no
  email) under a random device ID, with your operating system, "Claude Code" as the
  editor, and the plugin version. Each session start checks the plan and sends the same
  three details again.
- **The free limit:** after each spoken summary it reports the day's count (license and
  device ID, no content), so the limit holds across your computers.
- **Product events:** whether the setup finished, or the kind of failure (for example a
  network error, never a message), each once; on Code Advanced, one per day on which
  it was used. They carry the license and device ID, and no content.
- **Signing in** sends your email to Verbative to receive a code; **upgrading** sends your
  license so the order page opens for your account.

Details: [verbative.de/legal/privacy](https://verbative.de/legal/privacy/).

## Remove

`/plugin uninstall verbative-speak@verbative`. The downloaded voice lives in Verbative's
data folder under `plugin/` (macOS: `~/Library/Application Support/Verbative/plugin`,
Windows: `%APPDATA%\Verbative\plugin`) and can be deleted.

## License

Verbative for Claude Code is commercial software, free to use within the free plan:
see [LICENSE](LICENSE). The voice engine and hooks it downloads include open-source
components, listed with their licenses in
[verbative-dist/LICENSES](https://github.com/verbative/verbative-dist/tree/main/LICENSES).
The voice model is [Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) (Apache-2.0).
"Claude" is a trademark of Anthropic, PBC; Verbative is an independent product.

Questions: info@verbative.de
