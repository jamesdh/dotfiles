# Global CLAUDE.md

## Pre-Task Test Validation

Before beginning a new task — a new plan, a new feature, or a distinctly different direction from the prior work — run the project's test suite first. If any tests are failing, stop immediately and notify me. Failing tests should be addressed before starting new work.

Do NOT re-run tests for every follow-up instruction within the same task. Only run them when the work is clearly a new, separate effort.

## Testing Requirements

When adding or modifying features, always write tests that validate the changes.

- **Favor small, composable components.** Write code in reusable, compartmentalized units that are easy to unit test.
- **Use integration tests when unit tests aren't viable.** e.g., SwiftUI views interacting with macOS system APIs that require the running application. Write integration tests where possible, and acknowledge when manual testing is the only option.
- **Testability is the design goal.** Code that's easy to test tends to be easier to understand, easier to compose, and easier to maintain.

## Imports Over Fully Qualified Names

Always prefer importing types, functions, and modules at the top of the file over using fully qualified names (FQNs) inline. Inline FQNs are noisy, harder to read, and obscure the file's actual dependencies.

- **Import at the top of the file, even for one-offs.** Add a top-of-file import for any symbol referenced more than once, and prefer it for one-off references too.
- **Use inline FQNs only when an import won't work.** Reach for them only when an import would cause a genuine name collision or circular import that can't be resolved another way.
- **Match the file's existing import style.** When editing existing code, follow the established style of the file/module rather than introducing a new convention.

## Eagerly Search the Web

Treat web search as a primary investigation tool — on par with reading a file or grepping the codebase. Reach for it whenever there's uncertainty about unfamiliar libraries, API behavior, recent tooling changes, cryptic errors, or obscure configuration. Someone has almost certainly already hit and documented what you're looking at — find their answer instead of rediscovering it.

- **Search proactively, not reactively.** When an outside source can answer a question faster than experimentation can, search first and experiment with the answer in hand.
- **Search the moment something is unfamiliar.** Don't guess at a library's API, a flag's behavior, a config key's meaning, or an error code's cause — look it up before writing the code.
- **Paste the exact error string into WebSearch.** Use the exact error message (or a distinctive fragment of it) — do not paraphrase.
- **One non-obvious failure is enough reason to search.** If an attempt didn't work for a reason you don't fully understand, search before trying another variation. You're not "giving up" by searching — you're using the right tool.

## Convention Over Configuration

Popular frameworks (Micronaut, Spring, and similar) ship with strong conventions that eliminate boilerplate. Lean on them. Don't restate defaults the framework already provides, and don't reinvent abstractions the framework has already solved idiomatically.

- **Don't restate framework defaults.** e.g. Micronaut's `@MappedEntity` derives the table name from the class name — don't pass `@MappedEntity("customer")` on a `Customer` class. Same for column names, ID generation strategies, default content types, etc. (One legitimate reason to override is when the derived name collides with a SQL reserved word — e.g. a `User` or `Order` class — in which case explicit naming is correct.)
- **Prefer declarative HTTP clients.** Use Micronaut `@Client` or Spring `HttpExchange` / Feign over hand-wiring `HttpClient` / `WebClient` boilerplate.
- **Use repository abstractions for standard queries.** Micronaut Data or Spring Data conventions handle CRUD and derived-name queries. For more refined querying, reach for a typed query builder like jOOQ.
- **Raw SQL strings are a last resort, not a default.** If a Data repository or jOOQ can express the query, use that instead. Raw strings lose type safety, refactor support, and SQL-injection guarantees.
- **Check the docs before writing custom code.** When in doubt about whether a convention exists, the framework almost certainly has one.

## Do the Work, Don't Defer to Me

If you have the tools and access to do something yourself, do it. Don't ask me to check, look up, query, or run something on your behalf when you can do it directly.

- **Read files yourself.** If you need to know whether a file contains a key, read the file. Don't ask me.
- **Query the database yourself.** If you need to know whether a table contains a row, run the query. Don't ask me.
- **Inspect running state yourself.** Process info, installed versions, command output, open ports, etc. — run the check rather than asking.
- **Only ask when the answer truly requires me.** My intent, my preference, credentials I haven't shared, context outside the machine. Asking me to verify what you can verify yourself wastes a round trip and shifts work onto me.
- **Postgres runs in Docker, not on the host.** I rarely (if ever) have `psql` on the host pointed at a real database. Don't try `psql -U …` directly first and then fall back to Docker after it fails — go straight to `docker compose exec <service> psql …` (or `docker exec`) against the running container. If you can't find the container, check `docker ps` before assuming there's a host install.

## Verify Before Asserting

Before stating any factual claim about timestamps, PR numbers, file contents, code paths, or external data, run the read-only verification command first. Session memory and conversation summaries are not authoritative.

- **Query external state, don't describe it from memory.** API responses, schemas, and remote state should always come from a fresh call.
- **Earlier turns aren't ground truth.** Don't paraphrase from earlier in the conversation as if it were authoritative. Prior turns and summaries can be stale, abbreviated, or wrong.
- **Be especially careful with relative time.** You do not have reliable awareness of the current date/time, and you regularly miscompute things like "today / yesterday / last week / X days ago." Never translate a raw timestamp into a relative phrase without checking the current date (`date`) and the event's actual timestamp side by side. When in doubt, just state the absolute date/time and let me do the math.
- **Inspect database schemas before querying them.** You regularly hallucinate column or table names that sound plausible but don't exist. Before composing any non-trivial query, look up the actual schema — `\d <table>` (psql), `DESCRIBE <table>` / `SHOW COLUMNS` (MySQL), `information_schema.columns`, or whatever the equivalent is for the database in use. Don't guess column names from context; verify them.

## Link PRs to the Issues They Resolve

When a PR addresses an existing issue, always include a GitHub closing keyword (`Fixes #123`, `Closes #123`, `Resolves #123`) in the PR description so that merging the PR auto-closes the issue. A bare `#123` reference renders as a hyperlink but does not close anything on merge.

- **Use closing keywords, not bare references.** `Fixes #123`, `Closes #123`, or `Resolves #123` will auto-close the issue when the PR merges. `#123` alone only renders as a link.
- **The PR description is the required location; commit messages are optional.** GitHub recognizes closing keywords in either, but only a keyword in the PR description triggers the "Linked issues" panel in the PR sidebar that surfaces what will be closed on merge. Mirroring the keyword into the commit message is fine and preserves the link in history, but on its own it's not enough.
- **Cross-repo issues need the full reference.** Use `owner/repo#123` syntax (e.g. `Fixes moltenbits/conlingo#42`) when the issue lives in a different repository.
- **One keyword per issue.** If a PR closes multiple issues, list each with its own keyword: `Fixes #12, fixes #15, closes #18`. A single keyword followed by a comma-list does *not* close all of them.

## Commit attribution

When creating git commits or PRs on the user's behalf:

- **Don't add `Co-Authored-By:` trailers to commit messages.** No assistant or tool attribution in commit metadata.
- **Don't add "Generated with [Claude Code]" footers to PR bodies.** Same rule for PR descriptions.
- **Commits should appear under the user's identity only.** No assistant or tool attribution anywhere in the commit metadata.

### Agent worktrees

When spawning background agents with `isolation: "worktree"`:

- **Pick a kebab-case slug from the task.** e.g. `extended-hours-bg`, `flag-cleanup`. The slug becomes the branch and worktree name.
- **Rename the branch before any push.** In the agent's prompt, run `git branch -m <slug>`. The remote branch and PR head ref pick up the slug. Renaming after push orphans the PR.
- **Run two cleanup steps after the agent completes, before reporting back:**
    - `git worktree unlock <path>` — agent worktrees are created locked, and GUI clients (Tower) silently refuse to remove locked worktrees.
    - `git worktree move <old-path> <new-path>` to rename the worktree directory to match the slug, so `git worktree list` and Tower's sidebar are readable.
- **Don't retroactively rename a branch whose PR is already open.** The local branch diverges from the PR's head ref and the PR is stranded.
