# iTerm2 configuration

iTerm2 config is tracked as **two clean, purpose-split sources** — never the monolithic
`com.googlecode.iterm2.plist`, which iTerm rewrites on every quit (renormalizing color
blocks, bumping feature flags, saving window state) and which therefore produced a huge,
noisy diff every time. That plist is git-ignored on purpose.

| What | Where | Who owns it |
|------|-------|-------------|
| **Profiles** (colors, fonts, per-profile keybindings, working dirs, badges) | `iTerm.json` — an iTerm2 [Dynamic Profile](https://iterm2.com/documentation-dynamic-profiles.html), symlinked into `~/Library/Application Support/iTerm2/DynamicProfiles/` by `roles/osx/tasks/per_app/iterm.yml` | This file is the source of truth |
| **App-level settings** (tab bar, mouse/pointer, quit behavior, API server, …) | The `com.googlecode.iterm2` block in `roles/osx/defaults/main.yml`, applied via the custom `osx_defaults` module | That block is the source of truth |

## Editing profiles

The dynamic profiles are marked `"Rewritable": true`, so you can **edit a profile in the
iTerm GUI and iTerm writes the change straight back to `iTerm.json`** — then just commit the
diff. (If you ever want a profile to be strictly read-only / un-dirtyable, set its
`"Rewritable"` to `false`; GUI edits to it then won't persist.)

Automatic Profile Switching binds each profile to a project directory (see each profile's
`Bound Hosts` / `Working Directory`), and the `change_default_profile.py` AutoLaunch script
(symlinked by the role) flips the default profile as you `cd` around. That script uses the
iTerm Python API, which is why `EnableAPIServer` is set in the `osx_defaults` block.

## Editing app-level settings

Add/adjust keys in the `com.googlecode.iterm2` block in `roles/osx/defaults/main.yml`, then
deploy with `make install.filtered` and the `defaults` tag. Find a key's current value with
`defaults read com.googlecode.iterm2 <Key>`.

## Deliberately NOT tracked

- **The whole prefs plist** — see above. `LoadPrefsFromCustomFolder` is now `false`, so iTerm
  reads/writes the standard `~/Library/Preferences/com.googlecode.iterm2.plist` and never
  touches this repo. The stale `com.googlecode.iterm2.plist` still sitting in this folder is
  inert once that setting has been applied; it can be deleted.
- **Window Arrangements** (e.g. the ~200 KB "Growlrrr" arrangement) — that's saved window/
  session geometry, not config, and it's a large churn source. It lives only in your live
  prefs. Re-save it any time with *Window ▸ Save Window Arrangement*.
- **AI settings** (`AiModel`, `AiMaxTokens`, `AitermURL`, `AIFeature*`, …) — they change as
  the feature evolves and would go stale in git. Set them in the GUI as you like.
