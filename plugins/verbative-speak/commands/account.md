---
description: Your Verbative plan — upgrade to Code Advanced (unlimited spoken summaries), sign in, or sign out
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh:*)", "AskUserQuestion"]
disable-model-invocation: true
---

Walk the user through their plan. These are the only commands to run, each with the Bash tool, and nothing else:

- Your plan: `"${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh" cmd account`
- Upgrade: `"${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh" cmd account upgrade`
- Sign in (sends a code to the email): `"${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh" cmd account login '<email>'`
- Check the code: `"${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh" cmd account verify '<email>' '<code>'`
- Sign out: `"${CLAUDE_PLUGIN_ROOT}/bin/verbative.sh" cmd account logout`

Use an email only if it looks like one (letters, digits, and . _ % + - before and after a single @) and a code only if it's digits; otherwise say it doesn't look right and ask again.

If a command reports that something didn't work (a code that didn't verify, a code that couldn't be sent, or a sign-in this computer's VS Code extension handles), say so in one sentence, as it says, and offer to try again where that makes sense. First run the plan command and show the Plan and summaries lines from its output, as printed. Then ask with AskUserQuestion, header "Plan":

- **Plan: Free, Signed in: no.** Question "Code Advanced makes Verbative unlimited here, and adds Verbative Memory and the VS Code extension (14-day free trial for first-time subscribers). What would you like to do?" Options: "Upgrade to Code Advanced", "Sign in: I already have it", "Not now".
- **Plan: Free, signed in with an email.** Same question; options: "Upgrade to Code Advanced", "Sign out", "Not now".
- **Plan: Code Advanced.** Question "Signed in as <email> on Code Advanced. Anything to change?" Options: "Keep it", "Sign out", "Use another account".

If they typed a word after the command (upgrade, sign in, sign out), go straight to that step.

Then:
- **Upgrade to Code Advanced:** if not signed in yet, sign in first (below), so the purchase lands on this account. Then run the upgrade command. It opens the order step in their browser, for their account, without a second sign-in where the server allows it. Relay what its output says is left in one or two short sentences (usually: confirm the order there), and that Verbative here is unlimited from their next task, with nothing else to do.
- **Sign in / Use another account:** ask with AskUserQuestion, header "Email", question "Your email for Verbative? Type it below.", options "Cancel" and "See the plans first". With an email, run the sign-in command. "See the plans first": give https://verbative.de/pricing/ and stop.
- **After a code is sent:** ask with AskUserQuestion, header "Code", question "Type the code from the email sent to <email> below.", options "Send a new code" and "Cancel". With a code, run the check-the-code command; if it didn't work, say so and ask once more. "Send a new code": run the sign-in command again.
- **Sign out:** run the sign-out command.
- **Not now / Keep it / Cancel:** stop.

Finish with one sentence on where they stand.

How the plan works, if they ask:
- Free: 10 spoken summaries a day; approval reminders and "On it." don't count. After the tenth summary, Verbative is quiet until the next day (00:00 UTC).
- Code Advanced: unlimited, plus Verbative Memory and the VS Code extension's features. Plans at https://verbative.de/pricing/ (14-day free trial for first-time subscribers).
