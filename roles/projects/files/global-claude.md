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

## Convention Over Configuration

Popular frameworks (Micronaut, Spring, and similar) ship with strong conventions that eliminate boilerplate. Lean on them. Don't restate defaults the framework already provides, and don't reinvent abstractions the framework has already solved idiomatically.

- Don't repeat framework defaults. e.g. Micronaut's `@MappedEntity` derives the table name from the class name — don't pass `@MappedEntity("customer")` on a `Customer` class. Same for column names, ID generation strategies, default content types, etc. (One legitimate reason to override is when the derived name collides with a SQL reserved word — e.g. a `User` or `Order` class — in which case explicit naming is correct.)
- Prefer **declarative HTTP clients** (Micronaut `@Client`, Spring `HttpExchange` / Feign) over hand-wiring `HttpClient`/`WebClient` boilerplate.
- Use **Micronaut Data** or **Spring Data** repository conventions for standard CRUD and derived-name queries. For more refined querying, reach for a typed query builder like **jOOQ** — not hand-rolled SQL strings.
- Hand-rolled SQL strings are a last resort, not a default. If a Data repository or jOOQ can express the query, use that instead. Raw strings lose type safety, refactor support, and SQL-injection guarantees.
- When in doubt about whether a convention exists, check the framework docs before writing custom code. The convention is usually there.

## Do the Work, Don't Defer to Me

If you have the tools and access to do something yourself, do it. Don't ask me to check, look up, query, or run something on your behalf when you can do it directly.

- If you need to know whether a file contains a key, read the file. Don't ask me.
- If you need to know whether a database table contains a row, run the query. Don't ask me.
- If you need to know what a process is doing, what version is installed, what a command outputs, whether a port is open, etc. — run the check yourself.
- Asking me to verify something you're capable of verifying wastes a round trip and shifts work onto me. Only ask when the answer genuinely requires information I have and you don't (my intent, my preference, credentials I haven't shared, context outside the machine).

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
