---
description: Set up Verbative's voice — shows the hooks it adds to your Claude Code settings, and adds them when you say yes (remove takes them out again)
argument-hint: "[remove]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh:*)", "AskUserQuestion"]
disable-model-invocation: true
---

Verbative speaks through hooks in the user's own Claude Code settings. This command shows them, and adds or removes them only after the user says yes. These are the only commands to run, each with the Bash tool, and nothing else:

- Show what setup adds: `"${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh" setup preview`
- Add it: `"${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh" setup install`
- Show what removing takes out: `"${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh" setup preview-remove`
- Remove it: `"${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh" setup remove`

If they typed remove after the command:
1. Run the remove preview and copy its output into your reply word for word (the user doesn't see tool output). If it says there are no Verbative hooks, stop. It only shows what would be removed: don't say anything was removed yet.
2. Ask with AskUserQuestion, header "Remove", question "Remove Verbative's hooks from your Claude Code settings? Claude stops speaking until you run /verbative-speak:setup again.", options "Remove them" and "Keep them".
3. On "Remove them", run the remove command and show its output exactly as printed. On "Keep them", say nothing was changed.

Any other word after the command: say it takes remove or nothing, and stop.

Otherwise:
1. Run the preview command. The first time, it downloads Verbative's hooks program first, which takes a few seconds. If it says the hooks are already there, say Verbative is set up, and stop. If it says something didn't work, say so in one sentence, as it says, and stop.
2. Write its output into your reply, inside a ``` code block, every line exactly as printed, the hook lines included. The user can't see tool output: without this block they would be agreeing to hooks they haven't seen. This holds however you ask in step 3, with the question tool or in plain text. Don't summarize it, and don't say anything was added: nothing changes until they pick "Add them".
3. Then ask with AskUserQuestion, header "Setup", question "Add the hooks listed above to your Claude Code settings? They let Verbative speak: a short summary when a task finishes, and what Claude needs when it waits for you.", options "Add them" and "Not now". Give "Add them" a preview: the preview command's output, every line exactly as printed, so the hooks show right next to the choice.
4. On "Add them", run the add command and show its output exactly as printed. Then tell the user in one or two sentences: the voice downloads in the background now (about half a gigabyte, once, unless Verbative's VS Code extension already has it), and Claude starts speaking as soon as it's ready, in this session too; /verbative-speak:voice shows the status and settings. On "Not now", say nothing was changed.
