---
description: Use when the user asks about Verbative or Verbative Speak, about Claude speaking or reading its replies aloud, spoken summaries or approval reminders, or why nothing is spoken. Says how to set Verbative up and where its settings are.
user-invocable: false
---

Verbative Speak speaks through hooks in the user's own Claude Code settings. /verbative-speak:setup adds them: it shows them first and adds them only when the user says yes. Until then, nothing is spoken.

- Nothing is spoken, or they want to start: tell them to run /verbative-speak:setup. It's theirs to approve, so don't try to run it for them.
- The status, the voice, its speed, what it says when a task finishes, approval reminders, or switching the voice off and on: /verbative-speak:voice.
- Their plan (10 spoken summaries a day free, unlimited with Code Advanced), signing in or out: /verbative-speak:account.
- Removing it: /verbative-speak:setup remove, then /plugin uninstall verbative-speak.

Answer in a sentence or two and name the command. Run nothing.
