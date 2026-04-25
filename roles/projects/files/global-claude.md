# Global CLAUDE.md

## Pre-Task Test Validation

Before beginning a new task — a new plan, a new feature, or a distinctly different direction from the prior work — run the project's test suite first. If any tests are failing, stop immediately and notify me. Failing tests should be addressed before starting new work.

Do NOT re-run tests for every follow-up instruction within the same task. Only run them when the work is clearly a new, separate effort.

## Testing Requirements

When adding or modifying features, always write tests that validate the changes.

- Write code in reusable, compartmentalized components that are easy to unit test.
- When unit testing isn't feasible (e.g., SwiftUI views interacting with macOS system APIs that require the running application), write integration tests where possible and acknowledge when manual testing is the only viable option.
- Testable code is the goal — it tends to be easier to understand, easier to compose, and easier to maintain.

## Search the Web When Stuck

When a problem isn't yielding to the first couple of attempts, search the web before trying a third variation of the same approach. Cryptic errors, unfamiliar library behavior, recent API/tooling changes, and obscure config issues are usually solved in seconds by a search — someone else has almost certainly hit the same thing.

- Treat web search as a first-class debugging tool, not a last resort. Reach for it early, not after exhausting guesses.
- Paste the exact error message (or a distinctive fragment of it) into WebSearch. Do not paraphrase.
- Never give up on a problem as "too difficult" without having searched for it first.
- Cycling through variations of the same failing approach is the anti-pattern to avoid. If two attempts haven't worked, stop and search instead of trying a third.
