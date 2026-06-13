# Global Agent Instructions

## Basic Principles of Good Software Engineering

These are the load-bearing fundamentals of design — apply them as defaults, but treat them as heuristics, not laws. They sometimes pull against each other (DRY vs. KISS, abstraction vs. YAGNI), and the right call is whichever keeps the code simplest to understand and cheapest to change. Reach for them to reason about tradeoffs, not to win arguments by citation.

- **SOLID — five principles for object-oriented design:**
    - **Single Responsibility (SRP)** — a class or module should have one reason to change. If it has two unrelated responsibilities, split it.
    - **Open/Closed (OCP)** — open for extension, closed for modification. Add behavior by adding new code, not by editing code that already works.
    - **Liskov Substitution (LSP)** — a subtype must be usable anywhere its base type is expected, without surprising the caller. If a subclass has to weaken a guarantee, the hierarchy is wrong.
    - **Interface Segregation (ISP)** — prefer many small, client-specific interfaces over one fat one. No caller should depend on methods it never uses.
    - **Dependency Inversion (DIP)** — depend on abstractions, not concretions. High-level policy shouldn't import low-level detail; both should depend on an interface.
- **DRY (Don't Repeat Yourself).** Every piece of knowledge should have a single, authoritative home. But don't over-DRY — a little duplication is cheaper than the wrong abstraction, and coupling two things only because they look alike today is a trap.
- **KISS (Keep It Simple).** Prefer the simplest thing that works. Clever, dense, or "flexible" code that's hard to read is a liability; the obvious solution is usually the right one.
- **YAGNI (You Aren't Gonna Need It).** Build for the requirements you have, not the ones you imagine. Speculative generality and unused extension points add cost now for value that usually never arrives.
- **Separation of Concerns.** Keep distinct responsibilities — I/O, business logic, presentation, persistence — in distinct units. Mixing them makes each harder to change and test in isolation.
- **High Cohesion, Low Coupling.** Things that change together belong together (cohesion); things that don't should depend on each other as little as possible (coupling). This is the goal most of the other principles serve.
- **Modularity.** Decompose the system into self-contained units with clear boundaries and well-defined interfaces. A module should be understandable, replaceable, and testable on its own.
- **Encapsulation.** Hide internal state and implementation behind a stable interface. Callers depend on what a unit does, not how — so the how can change without breaking them.
- **Composition Over Inheritance.** Build behavior by combining small parts rather than extending deep class hierarchies. Composition is more flexible and avoids the fragile-base-class coupling that inheritance creates.
- **Law of Demeter (least knowledge).** A unit should talk only to its immediate collaborators, not reach through them (`a.getB().getC().doThing()`). Long reach chains couple you to the internal shape of things you don't own.
- **Principle of Least Astonishment.** Code should behave the way a reader reasonably expects. Names, signatures, and side effects should hold no surprises; surprising behavior is a defect even when it's technically "correct."

## Pre-Task Test Validation

Before beginning a new task — a new plan, a new feature, or a distinctly different direction from the prior work — run the project's test suite first. If any tests are failing, stop immediately and notify me. Failing tests should be addressed before starting new work.

Do NOT re-run tests for every follow-up instruction within the same task. Only run them when the work is clearly a new, separate effort.

## Testing Requirements

When adding or modifying features, always write tests that validate the changes. Prefer TDD: write the tests first, then write the code that makes them pass. Writing tests first forces you to think about the API up front and naturally pushes the implementation toward smaller, more encapsulated, more testable units.

- **Favor small, composable components.** Write code in reusable, compartmentalized units that are easy to unit test.
- **Use integration tests when unit tests aren't viable.** e.g., SwiftUI views interacting with macOS system APIs that require the running application. Write integration tests where possible, and acknowledge when manual testing is the only option.
- **Testability is the design goal.** Code that's easy to test tends to be easier to understand, easier to compose, and easier to maintain.
- **Cover edge and failure cases, not just the happy path.** A suite that only exercises the success path misses the bugs that actually ship. Test for null/empty inputs, boundary values, error conditions, invalid state, and concurrency where it applies.
- **For bug fixes, write the failing test first.** Reproduce the bug in a test that fails for the same reason the bug exists, then write the fix that turns it green. This proves the fix actually addresses the bug *and* prevents it from regressing silently later.

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

## Finish the Described Work — Don't Stop to Ask Permission Mid-Task

When I describe a task or a multi-part piece of work, complete **all** of it in one go. Don't stop partway to summarize progress and ask whether to continue. Keep going until the work is done, the tests pass, and it's committed. A list of parts (e.g. "Phase 2: A, B, and C") is a single mandate to finish A, B, *and* C — not a set of checkpoints to pause at.

- **Don't ask "want me to do X next?" when X is part of the work I already described.** Just do X. Asking is only warranted for something genuinely outside the described scope.
- **A progress summary is not a stopping point.** If you want to note what's done mid-task, note it and keep working in the same turn. Don't end your turn on a status report when there's described work left.
- **Don't self-impose scope reductions.** "I'll do the UI now and the streaming later" needs my explicit sign-off. If I asked for the whole thing, deliver the whole thing; don't unilaterally split it and hand part back to me.
- **Only stop early when you are genuinely blocked or done.** Blocked = a decision only I can make (a credential I haven't shared, an irreversible/destructive action needing sign-off, a real ambiguity that changes the outcome), or tests that fail and you can't fix. "This next part is big / infra-heavy / careful" is *not* a reason to stop — it's the work.
- **Effort and context length are not reasons to stop.** If the task is large, work through it; if you're running low on context, say so and keep going as far as you can rather than parking it back on me.

## A Question Gets an Answer, Not an Implementation

The rule above is about *described work* — directives. A question is not a directive. When I **ask** something, answer it; don't jump straight into implementing a change off the back of it. This is the counterweight to "finish the described work": finish what I told you to do, but don't manufacture work out of what I merely asked about.

- **Treat questions as questions.** "Is it possible to…", "Can we…", "Should we…", "Do we…", "What if…", "Why don't we…" are requests for information, feasibility, or a recommendation — not instructions to build. Answer, lay out the options/tradeoffs, and stop there.
- **A question is often me thinking, not me deciding.** I may be weighing whether it's worth doing, comparing it against another approach, or heading somewhere you can't see. Implementing pre-empts my decision and can churn the branch with work I never asked for.
- **Wait for the build signal.** Only start changing code on an explicit instruction — "do it", "add it", "implement", "make the change", "go" — or when it's unambiguously part of a task I already directed. "Can we?" is not "do it."
- **If a question might be an implied request, don't assume "yes, build it."** Answer it, say what you'd do and recommend, and let me give the go-ahead — or ask which I want. Erring toward action here is as wrong as erring toward stopping mid-task; calibrate to whether I gave a directive or asked a question.

## Verify Before Asserting

Before stating any factual claim about timestamps, PR numbers, file contents, code paths, or external data, run the read-only verification command first. Session memory and conversation summaries are not authoritative.

- **Query external state, don't describe it from memory.** API responses, schemas, and remote state should always come from a fresh call.
- **Earlier turns aren't ground truth.** Don't paraphrase from earlier in the conversation as if it were authoritative. Prior turns and summaries can be stale, abbreviated, or wrong.
- **Be especially careful with relative time.** You do not have reliable awareness of the current date/time, and you regularly miscompute things like "today / yesterday / last week / X days ago." Never translate a raw timestamp into a relative phrase without checking the current date (`date`) and the event's actual timestamp side by side. When in doubt, just state the absolute date/time and let me do the math.
- **Inspect database schemas before querying them.** You regularly hallucinate column or table names that sound plausible but don't exist. Before composing any non-trivial query, look up the actual schema — `\d <table>` (psql), `DESCRIBE <table>` / `SHOW COLUMNS` (MySQL), `information_schema.columns`, or whatever the equivalent is for the database in use. Don't guess column names from context; verify them.

## Write GitHub Issues for a Cleared Context

When creating a GitHub issue, write it as if a future session — yours or mine — will pick it up cold, with **none** of the conversation context that led to filing it. The reader will not remember our discussion, will not have the same mental model of the problem, and will not have access to the chat history. Externalize everything that matters into the issue body.

- **Assume zero context on the reader.** When you (or I, or a future you) come back to fix the issue, the context will be cleared. Write so the body alone is enough to act on — no "see our earlier discussion."
- **Capture the why, not just the what.** Reproduce the relevant reasoning, the constraints, the approaches that were ruled out, and any decisions made during the discussion. A two-line title isn't enough; the body has to stand alone.
- **Include concrete artifacts.** Error messages, file paths and line numbers, exact commands, observed vs expected behavior, relevant SHA/PR refs. Don't hand-wave with "the bug we discussed" — paste the actual evidence.
- **Richer discussion → longer issue body.** The more context the conversation has built up, the more important it is to dump that context into the issue. Treat the issue as the artifact that captures the discussion, not a placeholder that depends on it.

## Branches, Commits, and PRs

Treat one described task as a single lifecycle — **branch → commits → one PR** — where each stage has its own default. Keep them distinct; don't collapse "commit" or "branch" into "open a PR."

- **Branch first, from an up-to-date `main`.** When you start a new task, create its branch *before the first commit* — but sync the base first: switch to `main` and bring it current (`git switch main && git pull --ff-only`), then `git switch -c <kebab-slug>`. Do **not** branch off a stale local `main`, and do **not** branch off whatever branch you happen to be sitting on — it may be old or already merged. Never commit a new task's work directly onto `main`. One task = one branch. (Branching off an out-of-date `main` has caused real problems.)
- **Commit eagerly; no need to ask.** Once the test suite is green, commit. Prefer several small, logical commits on the branch (a refactor, a feature, a bug fix, a passing test) over one giant commit. Commits stay **local** — committing never implies pushing.
- **Push only when I ask or when opening a PR.** Pushing is a separate, explicit action — not a default that follows from a green commit. Push only when I ask for it ("push"), or as the necessary first step of a PR I've asked you to open. A branch with green local commits stays unpushed until then; don't push it just because the work is done.
- **Open a PR only when I ask.** Creating a PR is a separate, explicit action — wait for "open a PR" / `gh pr create`. Local commits on the task branch are fine indefinitely until then; the push happens as part of opening the PR.
- **One described task = one branch = one PR.** Don't split a single task across multiple PRs. If the task has phases or parts, they are *more commits on the same branch* — not new branches or follow-up PRs. If you catch yourself thinking "part A now, part B in a follow-up PR," stop and keep them on one branch.
- **Fixes to an in-flight PR go *on* that PR.** If I flag a problem with an open PR, push the fix as new commits to that PR's branch and update its body — never a new branch stacked behind it. If new work feels genuinely separate from the open PR, ask before branching rather than stacking.

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
