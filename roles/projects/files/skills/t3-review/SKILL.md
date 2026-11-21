---
name: t3-review
description: >-
  Manual invocation only (when the user runs /t3-review or $t3-review).
  Do not auto-activate. Configures a persistent cross-thread code review loop
  over t3_thread_send: bare invocation makes this thread the persistent
  reviewer; invoking with an attached/referenced thread configures this thread
  as the coding side sending review requests to that reviewer thread.
disable-model-invocation: true
---

# Persistent T3 Cross-Thread Review (`/t3-review`)

Determine the role from whether the user referenced or attached a reviewer thread alongside `/t3-review` / `$t3-review` (in `$ARGUMENTS` or in the message/attachments).

## Mode 1: Reviewer (no thread argument)

Use this mode when invoked with no thread reference.

- You are the persistent reviewer for the requesting thread.
- If no review request has arrived yet, briefly confirm you are ready and stop.
- For each incoming review request:
  - Review **only** what the request covers. Do not modify any files.
  - Send numbered **P0–P3 findings** (preserving finding numbers across follow-up rounds)—or **“Clear to commit”**—back to the requesting thread using `t3_thread_send`.
  - Stop after replying.

## Mode 2: Coding / Requesting Side (thread referenced or attached)

Use this mode when invoked with a thread reference (e.g., an attached `@` thread, thread link, or thread ID).

- Use the referenced/attached thread as your persistent reviewer for this session.
- Send review requests through `t3_thread_send` directly (do not switch to `delegate_task` or Sideband for these reviews).
- Look up your own T3 Code `threadId` by calling `t3_thread_configure()` with no `threadId` argument (do not guess or pass a harness/session ID).
- Include in every review request sent via `t3_thread_send`:
  - Your own T3 `threadId` for replies
  - The checkout path
  - The review scope
  - Validation / test results
- Reuse that same reviewer thread via `t3_thread_send` for all follow-up rounds.
- If the user only ran `/t3-review @<thread>` to configure the pairing, briefly confirm and wait; if they also asked to send a review right away, send it now.
