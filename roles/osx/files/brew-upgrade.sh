#!/bin/bash
# Nightly Homebrew upgrade, run by the com.jamesdh.brew-upgrade LaunchAgent at 02:00.
# HOMEBREW_NO_ASK: brew's "ask mode" (default-on for developer-mode installs since 4.5)
# prompts "Do you want to proceed?" on upgrades. It already skips itself without a TTY,
# but disabling it explicitly keeps manual runs of this script non-interactive too.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/bin:/bin"
export HOMEBREW_NO_ASK=1
export HOMEBREW_NO_ENV_HINTS=1

# Match bootstrap.sh: prefer the external cache when it is available, but leave
# HOMEBREW_CACHE undefined so Homebrew chooses its normal cache on other machines.
if [[ -d /Volumes/SDXC/Homebrew ]]; then
  export HOMEBREW_CACHE=/Volumes/SDXC/Homebrew
fi

echo "==> brew upgrade started $(date '+%Y-%m-%d %H:%M:%S')"

# TCC probe: upgrading casks in place needs the "App Management" grant, and macOS only
# raises its prompt when an app bundle is actually modified — which a fully up-to-date
# run never does. Probe with the same ruby brew upgrades run under (so the grant lands on
# the right client): a write-then-delete inside a brew-managed bundle (iTerm2 ships in
# Brewfile.bootstrap, so it's always present) leaves the bundle unchanged but raises the
# prompt when the grant is missing. A denial just raises EPERM, which the rescue swallows.
BREW_RUBY="/opt/homebrew/Library/Homebrew/vendor/portable-ruby/current/bin/ruby"
if [[ -x "$BREW_RUBY" && -d "/Applications/iTerm.app" ]]; then
  "$BREW_RUBY" -e '
    probe = "/Applications/iTerm.app/.brew-upgrade-tcc-probe"
    begin
      File.write(probe, "")
      File.delete(probe)
    rescue SystemCallError
    end
  ' || true
fi
# Non-fatal: a single unreachable tap (e.g. a private tap whose SSH key lives in a
# locked 1Password agent overnight) fails `brew update`; still upgrade what we have.
brew update || echo "==> brew update failed; continuing with upgrade anyway"
brew upgrade
echo "==> brew upgrade finished $(date '+%Y-%m-%d %H:%M:%S')"
