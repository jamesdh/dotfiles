#!/bin/bash
# Nightly Homebrew upgrade, run by the com.jamesdh.brew-upgrade LaunchAgent at 02:00.
# HOMEBREW_NO_ASK: brew's "ask mode" (default-on for developer-mode installs since 4.5)
# prompts "Do you want to proceed?" on upgrades. It already skips itself without a TTY,
# but disabling it explicitly keeps manual runs of this script non-interactive too.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/bin:/bin"
export HOMEBREW_NO_ASK=1
export HOMEBREW_NO_ENV_HINTS=1

echo "==> brew upgrade started $(date '+%Y-%m-%d %H:%M:%S')"
# Non-fatal: a single unreachable tap (e.g. a private tap whose SSH key lives in a
# locked 1Password agent overnight) fails `brew update`; still upgrade what we have.
brew update || echo "==> brew update failed; continuing with upgrade anyway"
brew upgrade
echo "==> brew upgrade finished $(date '+%Y-%m-%d %H:%M:%S')"
