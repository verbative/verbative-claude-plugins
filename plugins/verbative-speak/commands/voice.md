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
