# Global CLAUDE.md

## Pre-Task Test Validation

Before beginning a new task — a new plan, a new feature, or a distinctly different direction from the prior work — run the project's test suite first. If any tests are failing, stop immediately and notify me. Failing tests should be addressed before starting new work.

Do NOT re-run tests for every follow-up instruction within the same task. Only run them when the work is clearly a new, separate effort.

## Testing Requirements

When adding or modifying features, always write tests that validate the changes.

- Write code in reusable, compartmentalized components that are easy to unit test.
- When unit testing isn't feasible (e.g., SwiftUI views interacting with macOS system APIs that require the running application), write integration tests where possible and acknowledge when manual testing is the only viable option.
- Testable code is the goal — it tends to be easier to understand, easier to compose, and easier to maintain.

## Imports Over Fully Qualified Names

Always prefer importing types, functions, and modules at the top of the file over using fully qualified names (FQNs) inline. Inline FQNs are noisy, harder to read, and obscure the file's actual dependencies.

- Add a top-of-file import for any symbol referenced more than once, and prefer it for one-off references too.
- Only use an inline FQN when an import would cause a genuine conflict (name collision) or circular import that can't be resolved another way.
- When editing existing code, follow the established import style of the file/module.

## Search the Web When Stuck

When a problem isn't yielding to the first couple of attempts, search the web before trying a third variation of the same approach. Cryptic errors, unfamiliar library behavior, recent API/tooling changes, and obscure config issues are usually solved in seconds by a search — someone else has almost certainly hit the same thing.

- Treat web search as a first-class debugging tool, not a last resort. Reach for it early, not after exhausting guesses.
- Paste the exact error message (or a distinctive fragment of it) into WebSearch. Do not paraphrase.
- Never give up on a problem as "too difficult" without having searched for it first.
- Cycling through variations of the same failing approach is the anti-pattern to avoid. If two attempts haven't worked, stop and search instead of trying a third.

## Commit attribution

When creating git commits or PRs on the user's behalf:

- **Don't add `Co-Authored-By:` trailers** to commit messages — no assistant or tool attribution.
- **Don't add "Generated with [Claude Code]" footers** to PR bodies.
- Commits should appear under the user's identity only.

### Agent worktrees

When spawning background agents with `isolation: "worktree"`:

- **Pick a kebab-case slug** from the task (e.g. `extended-hours-bg`, `flag-cleanup`).
- **In the agent's prompt, rename the branch before any push**: `git branch -m <slug>`. The remote branch and PR head ref pick up the slug. Renaming after push orphans the PR.
- **After the agent completes**, run two cleanup steps before reporting back:
    - `git worktree unlock <path>` — agent worktrees are created locked, and GUI clients (Tower) silently refuse to remove locked worktrees.
    - `git worktree move <old-path> <new-path>` to rename the worktree directory to match the slug, so `git worktree list` and Tower's sidebar are readable.
- **Don't retroactively rename** a branch whose PR is already open — the local branch diverges from the PR's head ref and the PR is stranded.
