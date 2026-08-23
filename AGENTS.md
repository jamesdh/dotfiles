# AGENTS.md

This file provides guidance to AI coding agents — Claude Code (via the `CLAUDE.md` symlink) and Codex — when working with code in this repository.

## Overview

This is an Ansible-based macOS configuration management repository. It automates system setup, application installation, and development environment provisioning using Ansible playbooks and roles.

## Commands

```bash
# Installation
make bootstrap              # Initial setup (Xcode, Homebrew, 1Password, Python venv)
make install                # Run full Ansible playbook
make install.priority       # Install high-priority items only (triggers logout)
make install.nonpriority    # Install lower-priority items
make install.filtered       # Interactive tag filtering
make install.homelab        # Run homelab playbook on remote server

# Validation
make compare                # Dry-run check against current state
make compare.filtered       # Filtered dry-run
make list.tags              # List available Ansible tags
make list.tasks             # List all tasks

# Secrets
make secrets.decrypt        # Decrypt all vault files for editing
make secrets.encrypt        # Re-encrypt vault files (only if changed)

# Homebrew
make apps.check             # Verify Brewfiles match installed apps
make apps.update            # Install/update from Brewfiles
make apps.diff              # Show apps not in Brewfiles
```

## Architecture

### Playbooks
- `ansible.yml` - Main playbook for localhost (macOS)
- `homelab.yml` - Remote playbook for Ubuntu server (Docker/Portainer/Home Assistant)

### Roles
- **base** - Shell environment (zsh, Oh My Zsh, dotfiles in `roles/base/files/dotfiles/`)
- **ssh** - SSH config and 1Password key integration
- **osx** - macOS system preferences, Homebrew apps, per-app configuration
- **projects** - Git repos, SDKs (SDKMAN), Makefiles, /etc/hosts entries

### Tagging
- `priority` - Essential items for initial setup (runs with logout after)
- `nonpriority` - Optional items for later
- Role/feature tags: `osx`, `ssh`, `base`, `projects`, `apps`, `iterm`, `tower`, `code`, etc.

## Secrets

Vault files use pattern `*.vault.*` and are encrypted with Ansible Vault. Password is stored in `~/.ansible/dotfiles_vaultpass` (retrieved from 1Password during bootstrap).

**Workflow:**
1. `make secrets.decrypt` - Creates plaintext files and `.enc` backups
2. Edit the plaintext files
3. `make secrets.encrypt` - Re-encrypts only if content changed

Vault files are in:
- `roles/*/vars/main/*.vault.yml` - Ansible variables
- `roles/*/files/*.vault.*` - Env files and Makefiles

**Committing — encrypt first:** The `*.vault.*` files are normally left **decrypted** in the working tree so they're usable day-to-day. That means they routinely show as modified in `git status` even when you haven't edited them — that diff is just the plaintext form, *not* a real change. **Always run `make secrets.encrypt` before committing** so commits never contain plaintext secrets; treat a dirty vault file as "needs encrypting," not "unrelated change." (A cleaner setup — e.g. sourcing these straight from 1Password — would avoid the decrypted-by-default state; worth exploring, but this works for now.)

**op-fast pilot (workspace env):** `roles/projects/files/projects.env` holds 1Password secret *references* (`op://…`), not secrets — it's committed in plaintext and is **not** a vault file. The workspace `.envrc` (`projects.envrc`) resolves the references at direnv-load time via `op-fast` (Homebrew: `cometkim/tap/op-fast`), which caches resolved values in the macOS Keychain — encrypted at rest, ~10ms reads, and still working offline within the TTL (30 days, configured in `roles/osx/files/op-fast/config.toml`). The remaining `*.vault.env` files are candidates for the same conversion, which would eventually retire the encrypt/decrypt workflow above.

## Git Workflow

**No branches, no PRs in this repo — commit straight to `master` and push.** This overrides the general branch-per-task rule in the global agent instructions. It's a single-maintainer config repo, so a feature branch and PR add ceremony without adding review. Do **not** run `git switch -c` for a change here, and do not open a PR.

- **The default branch is `master`, not `main`.**
- **Still verify the base is current before committing.** Committing directly to `master` makes a stale base *more* likely to bite, not less: `git fetch origin --prune --tags`, then `git rev-list --left-right --count master...origin/master` must print `0	0` before you commit. If it doesn't, stop and say so.
- **Push is still a separate action** — commit freely, but push only when asked (or when the change is one I asked you to land).

## Key Locations

| Purpose | Location |
|---------|----------|
| macOS defaults | `roles/osx/defaults/main.yml` |
| Brewfiles | `roles/osx/files/Brewfile*` |
| Shell dotfiles | `roles/base/files/dotfiles/` |
| Per-app config tasks | `roles/osx/tasks/per_app/` |
| Custom Ansible module | `library/osx_defaults.py` |
| Projects config | `roles/projects/defaults/main.yml` |

## Conventions

- Tasks use `when:` clauses for conditional execution based on file/package existence
- 1Password lookups (`community.general.onepassword`) retrieve licenses and credentials
- `check_mode: no` on tasks that must run even in dry-run mode
- **No `tags: always` on probe tasks.** `always` defeats `--tags`, so the probe fires on every unrelated filtered run (`make install.filtered` with one tag ran half the per-app checks). When two blocks with mutually exclusive tag sets (typically `--tags=export` vs `--skip-tags=export`) each need the same probe, repeat the probe inside each block rather than hoisting it; if the value is needed across files, express it as a lazily-evaluated var (see `is_laptop`) instead of a registered task
- Brewfiles split by priority: `Brewfile.bootstrap`, `Brewfile.priority`, `Brewfile.privileged`, `Brewfile.nonpriority`, `Brewfile.mas` (App Store apps — installed by ansible with become, since mas needs root and brew bundle cannot sudo without a tty), `Brewfile.fonts`
- Machine-profile roles: `roles/personal`, `roles/proximal`, `roles/dev` — run after the shared roles, selected by `~/.dotfiles-profile` (`personal`, `proximal`, `dev`, or `base` for none; prompted once by bootstrap.sh, or by ansible pre_tasks if the file is missing). Each owns its `files/Brewfile`; the aggregate `Brewfile` includes the matching one for `make apps.*`. `base` skips silently; missing/unknown warns and runs none. Laptop-vs-desktop gating uses battery presence (`is_laptop` in `roles/osx/defaults/main.yml` — a lazily-evaluated `pipe` lookup, not a registered task, so tag-filtered runs don't shell out for it), NOT the model id — modern Apple Silicon ids (`Mac16,10`) don't contain "Book".

<!-- CLAUDE.md is a symlink to this file, so the AgentBridge block below is a hand-merged, agent-neutral
     version of the two per-agent sections `abg init` writes (a Claude-perspective one into CLAUDE.md, a
     Codex-perspective one into AGENTS.md, same markers). Re-running `abg init` here would replace it with
     the Codex-only version — re-merge if you do. -->
<!-- AgentBridge:start -->
## AgentBridge — Multi-Agent Collaboration

You are working in a **multi-agent environment** powered by AgentBridge. Two agents share this file — **Claude** (Claude Code, by Anthropic) and **Codex** (by OpenAI) — each running in its own parallel session on this machine. Work out which one you are and follow the lines addressed to you; everything else applies to both.

### Communication mechanism (read this first)
- **Claude → Codex**: Claude uses its AgentBridge MCP tools (`reply` / `get_messages`). Those tools exist only on Claude's side; what Claude sends arrives in Codex's session as a new user turn.
- **Codex → Claude**: AgentBridge is a **transparent proxy** on Codex's side — Codex has no tool to "send a message to Claude". Codex just writes its normal response; the bridge intercepts that `agentMessage` output and forwards it to Claude as a push notification (if a push fails, Claude drains the fallback queue with `get_messages`).
- **Do not** (Codex) search the AgentBridge source for a Codex-side "send" / "reply" / "sendToClaude" API — it does not exist and looking for it wastes turns; just write the reply as normal text. (Claude) If Codex complains it can't find such an API, remind it that its side is transparent.

### Message markers (Codex)
Codex puts a marker at the **very start** of each `agentMessage` (it must be the first text — e.g. `[IMPORTANT] Task done`, not `Task done [IMPORTANT]`) and keeps `agentMessage` for high-value communication only:
- `[IMPORTANT]` — decisions, reviews, completions, blockers
- `[STATUS]` — progress updates
- `[FYI]` — background context

### When to collaborate vs. work solo
- **Collaborate** when the task benefits from a second perspective, parallel execution, or capabilities the other agent has.
- **Work solo** for simple, self-contained tasks where the coordination overhead isn't worth it.
- When in doubt, **propose a task split** to the other agent rather than doing everything yourself.

### Capability comparison
| Capability | Claude | Codex |
|---|---|---|
| Architecture & planning | Strong | Moderate |
| Code review & analysis | Strong | Strong |
| Sandboxed code execution | No | Yes |
| Reproduce & verify bugs | Limited | Strong |
| File editing & refactoring | Yes (via tools) | Yes (via sandbox) |
| Web search & docs | Yes | Limited |
| Independent verification | Cross-review | Reproduce & test |

### How to start collaborating
1. When you receive a complex task, **proactively propose a division of labor** — Claude via the `reply` tool, Codex simply in its response (Claude receives it).
2. State what you'll handle and what you'd like the other agent to take on.
3. Ask for the other agent's agreement or counter-proposal before proceeding.
4. After task completion, **cross-review** each other's work.

### Role guidance
- Default roles — Claude: **Reviewer, Planner, Hypothesis Challenger**; Codex: **Implementer, Executor, Verifier**.
- Analytical / review tasks: **Independent Analysis & Convergence**.
- Implementation tasks: **Architect → Builder → Critic**.
- Debugging tasks: **Hypothesis → Experiment → Interpretation**.
- Do not blindly follow the other agent — challenge with evidence when you disagree.
- Use explicit collaboration phrases: "My independent view is:", "I agree on:", "I disagree on:", "Current consensus:".

### Budget pacing — drive the WEEKLY quota to ~100% over the week, evenly, without reaching a 5h cap (active when agent-quota-guard is installed)
- **Core principle: token is the means, value is the end.** Raising intensity means producing more real parallel value (deeper reviews, more independent exploration / verification / genuine subtasks) — never manufacturing low-value work to consume quota. The budget to MAXIMIZE is the **weekly** quota (refreshed once a week): drive each side's weekly toward ~100% by its weekly reset, and consume it **evenly** across the week — front-loading then starving, or under-consuming throughout, both leave weekly quota unredeemed (forfeited). The **5h window is NOT a quota bucket to fill — it is a RATE CAP**: stay under it within any 5h period; reaching it = a forced pause until the 5h resets = wasted time, not progress.
- **Re-query your budget before EVERY allocation decision** — Claude: `get_budget` → **rendered text** covering both sides; Codex: `check_budget` with `agent:"claude"|"codex"` → **normalized JSON**, per side. (Two different shapes — read the right one below.) Never reuse remembered numbers: a weekly window can refresh EARLY (resetting both 5h and weekly), fully restoring a side you believed was exhausted.
- **Even-pacing test (per side — Claude runs it)** — compare two quantities: *budget-windows* = how many 5h windows the weekly quota still covers at the current burn rate; *clock-windows* = how many 5h windows physically fit before the weekly reset = (weekly reset − now) ÷ 5h. **Claude** (`get_budget` text) carries BOTH, pre-computed for BOTH sides: the lines "按当前节奏，周额度还够 … 个 5h 窗口" (budget-windows) and "距周刷新还能容纳 … 个 5h 窗口（时钟）" (clock-windows). **Codex** (`check_budget` JSON) today carries only per-bucket `util` / `reset_epoch` / `reset_after_seconds` — no burn rate, no `five_hour_windows_left` — so Codex CANNOT compute budget-windows itself; it reads its weekly `util` and clock-windows only. To locate Codex's weekly bucket: of the `buckets[]` entries whose `id` contains `seven_day` or `secondary_window` (there can be several — e.g. a model-specific `additional_rate_limits[…]` one at 0%), take the HIGHEST-util one (the binding account-level window, matching how the bridge parses it); its clock-windows = `reset_after_seconds` ÷ 5h (never the top-level `reset_epoch`, which tracks the current limiter, not necessarily the weekly window). For the budget-windows half and the raise/hold/reduce verdict, Codex relies on Claude's `get_budget` (the burn projection lives there, for both sides) and reports its own weekly `util` + reset timing so Claude can run the test. (If a future `check_budget` exposes `five_hour_windows_left` on the weekly bucket, Codex reads it directly.) **The verdict (Claude computes it, per side):** budget > clock → **under-consuming** (weekly will be left unused) → **raise intensity**; budget < clock → **over-consuming** (won't last to the weekly reset) → **reduce intensity**; within ~1 window, or no confident rate → **hold**. **Codex, absent a fresh Claude verdict, holds at its current intensity (it never escalates unilaterally) and stays clear of the 5h cap — surfacing its weekly `util` + reset timing so Claude can issue the verdict.**
- **Raise intensity — use the levers your role has.** Orchestrator (Claude): pick larger, more-decomposable tasks; run more parallel subagents at once (3–5+ vs 1); raise delegation density; open more concurrent streams (review + explore + verify in parallel). Executor (Codex): go deeper in-turn, take larger chunks, run more verification/repro. Both: deepen quality (multi-angle review, broader test/repro) — never manufacture make-work. **Reduce intensity:** fewer/serial subagents (Claude), short bounded chunks, defer optional deep work. Stay below the **动态暂停线** (shown in `get_budget`; its `余量` = headroom from your current util to that soft line, measured on the resettable hard-winner window — the 5h OR the weekly window, whichever currently limits you) — that soft ceiling, not the raw 5h cap, is the "do not cross, avoid a forced pause" line. **If that line is absent, or you only have JSON (Codex),** fall back to the 5h bucket's raw util vs 100% (Codex: of the `buckets[]` entries whose `id` contains `five_hour` or `primary_window`, take the HIGHEST-util one) and keep clear of the 5h cap.
- **Distinguish 5h from weekly:** a 5h window resetting does NOT consume or waste weekly budget — it only refreshes your rate headroom, so you can keep going when weekly is under-consumed. A near 5h reset is therefore not urgency but the release of a rate limit. The real "unused = forfeited" is the **weekly budget as its WEEKLY reset nears**: if weekly is still under-consumed then, raise intensity (within the 5h cap) to use it. If even pacing needs a rate beyond one 5h window's capacity, you are rate-limited → keep each 5h window as full as possible (under the cap).
- **Two-subscription imbalance — the quotas are INDEPENDENT and differ in BOTH amount AND reset timing** (each side's weekly and 5h windows reset on different clocks). **The cross-side split is the orchestrator's (Claude) decision:** route more work to the side that is MORE under-consuming on the even-pacing test (the larger budget-windows − clock-windows gap); when EITHER side lacks a confident rate (so the gap can't be compared), fall back to the more budget-rich side (larger absolute weekly headroom). On any tie (equal gap, or equal headroom), prefer the side whose **weekly resets SOONER** (its leftover is forfeited earlier). **As the executor (Codex) you do NOT decide the global split** — execute what you're assigned, and when your own budget is rich report it (with evidence) so Claude routes more to you. The tighter / over-consuming side carries less.
- **Side-aware pause (the hard floor the code enforces — obey, do not reinvent), with each side's own action:** **Codex exhausted** (`system_budget_pause`) → Codex's turns stop (gate closed); **Claude** must not retry replies and continues solo on independent work, checkpointing the split point — but the SAME `system_budget_pause` is ALSO emitted when both sides are exhausted, so do not infer "solo" from the directive name alone: read its content (it names the paused side[s]) or re-check `get_budget`, and continue solo ONLY while Claude's own side is healthy; if Claude is also at its line, handle it as **Both** below. **Claude exhausted** (`system_budget_handoff`) → **Claude** sends ONE handoff (remaining tasks / context / artifact locations / acceptance criteria) then stops; **Codex** receives the baton and carries the work forward as far as its remaining quota allows that turn. **Both** → joint pause; checkpoint and wait for `resume` (Claude's own quota-guard also hard-stops Claude independently). A transient probe **429 is NOT exhaustion** → fall back to cached util and keep working.
<!-- AgentBridge:end -->
