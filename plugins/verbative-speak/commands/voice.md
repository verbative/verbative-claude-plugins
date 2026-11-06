---
description: Verbative's voice — status and settings (voice, speed, what it says, approval reminders), or off, on, test
argument-hint: "[off | on | test]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh:*)", "AskUserQuestion"]
disable-model-invocation: true
---

These are the only commands to run, each with the Bash tool, and nothing else:

- Status and settings: `"${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh" cmd status`
- Switch the voice off: `"${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh" cmd off`
- Switch it on: `"${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh" cmd on`
- Play a test line: `"${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh" cmd test`
- Save settings: `"${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh" cmd set voice=<voice> speed=<speed> summary=<summary|done> approvals=<on|off>`, with only the settings that change. It checks them, saves them and plays a sample.
- Check the setup: `"${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh" setup status`
- Show what setup adds: `"${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh" setup preview`
- Add it: `"${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh" setup install`

**First, every time, run the setup check.** If its output says the hooks are in your Claude Code settings, go on below. If it says Verbative doesn't run on this computer, or couldn't download what it needs, show that as printed and stop. Otherwise Verbative isn't set up yet, and these four steps come before anything else:

1. Run the setup preview.
2. **Show the preview.** Write its output into your reply, inside a ``` code block, every line exactly as printed, the hook lines included. The user can't see tool output: without this block they would be agreeing to hooks they haven't seen. This holds however you ask in step 3, with the question tool or in plain text. Don't summarize it, and don't say anything was added: nothing changes until they pick "Add them".
3. Then ask with AskUserQuestion, header "Setup", question "Verbative isn't set up yet, so nothing is spoken. Add the hooks listed above to your Claude Code settings now?", options "Add them" and "Not now". Give "Add them" a preview: the preview command's output, every line exactly as printed, so the hooks show right next to the choice.
4. On "Add them", run the add command and show its output exactly as printed, and say in one sentence that the voice downloads in the background (about half a gigabyte, once, unless Verbative's VS Code extension already has it) and Claude starts speaking as soon as it's ready. On "Not now", say /verbative-speak:setup does it any time.

Then go on below.

If they typed off, on or test after the command, run that one command, show its output exactly as printed, and stop. Any other word: say the command takes off, on or test, and stop.

Otherwise, run the status command, then help the user change the settings:

1. Show the status and settings from its output (everything above "Voices:") exactly as printed, in a code block.
2. Ask with the AskUserQuestion tool, in ONE call with these four questions. In each, put the current value first with " (current)" after it; the tool adds a "Type something" choice itself.
   - header "Voice", question "Which voice should read Claude's summaries? Type something for another: <every voice from the Voices line>": the current voice, then three more from the list, mixing American and British, female and male (for example Michael (American, male), Heart (American, female), Emma (British, female), George (British, male)).
   - header "Speed", question "How fast should it speak?": 1.0 (normal), 1.3 (default), 1.6 (faster), 2.0 (fastest). If the current speed is none of these, put it first and leave out the one closest to it (four options at most).
   - header "When done", question "What should it say when a task finishes?": Read the summary; Just say “Done.”
   - header "Approvals", question "Should it tell you when Claude waits for your approval?": On; Off.
3. Run the save command once, with only the answers that differ from the current settings, as plain words: voice is one name from the Voices line (for example voice=Emma), speed a number from 0.5 to 2 (speed=1.6), summary is summary (read the summary) or done (just say "Done."), approvals is on or off. A typed voice that isn't on the Voices line, or a speed that isn't a number: say so and ask again, without running anything.
4. Tell the user in one sentence what changed. If its output says nothing was changed, say why in one sentence and offer to try again. If nothing changed or they cancelled, say the settings stay as they are, and run nothing.
