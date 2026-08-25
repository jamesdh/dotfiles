#!/bin/bash
# Two-stage Homebrew upgrades:
#   fetch   downloads outdated packages at 02:00 without installing them;
#   watch   waits for an unlocked GUI session and runs one pending upgrade attempt.
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/bin:/bin"
export HOMEBREW_NO_ASK=1
export HOMEBREW_NO_ENV_HINTS=1

STATE_DIR="$HOME/Library/Caches/com.jamesdh.brew-upgrade"
PENDING_FILE="$STATE_DIR/pending"
ATTEMPTED_FILE="$STATE_DIR/attempted"

# Match bootstrap.sh: prefer the external cache when it is available, but leave
# HOMEBREW_CACHE undefined so Homebrew chooses its normal cache on other machines.
if [[ -d /Volumes/SDXC/Homebrew ]]; then
  export HOMEBREW_CACHE=/Volumes/SDXC/Homebrew
fi

mkdir -p "$STATE_DIR"

log() {
  echo "==> $* $(date '+%Y-%m-%d %H:%M:%S')"
}

fetch_upgrades() {
  local formula_output cask_output package pending_tmp
  local -a formulae=()
  local -a casks=()

  log "Homebrew download started"
  echo "==> Cache: $(brew --cache)"

  # A single unreachable tap should not prevent downloads from the metadata we
  # already have (for example, when a private tap's 1Password SSH key is locked).
  brew update || echo "==> brew update failed; continuing with existing metadata"

  formula_output="$(brew outdated --formula --quiet)"
  cask_output="$(brew outdated --cask --quiet)"

  while IFS= read -r package; do
    [[ -n "$package" ]] && formulae+=("$package")
  done <<< "$formula_output"
  while IFS= read -r package; do
    [[ -n "$package" ]] && casks+=("$package")
  done <<< "$cask_output"

  if (( ${#formulae[@]} == 0 && ${#casks[@]} == 0 )); then
    rm -f "$PENDING_FILE" "$ATTEMPTED_FILE"
    log "Homebrew is already up to date"
    return
  fi

  if (( ${#formulae[@]} > 0 )); then
    brew fetch --retry --deps --formula "${formulae[@]}"
  fi
  if (( ${#casks[@]} > 0 )); then
    brew fetch --retry --cask "${casks[@]}"
  fi

  pending_tmp="$(mktemp "$STATE_DIR/pending.XXXXXX")"
  {
    printf 'generation\t%s\n' "$(date '+%s')"
    for package in "${formulae[@]}"; do
      printf 'formula\t%s\n' "$package"
    done
    for package in "${casks[@]}"; do
      printf 'cask\t%s\n' "$package"
    done
  } > "$pending_tmp"
  chmod 600 "$pending_tmp"
  mv "$pending_tmp" "$PENDING_FILE"

  echo "==> Downloaded ${#formulae[@]} formula(e) and ${#casks[@]} cask(s)"
  log "Homebrew download finished"
}

screen_is_unlocked() {
  local console_user session_state

  console_user="$(/usr/sbin/scutil <<< 'show State:/Users/ConsoleUser' |
    /usr/bin/awk '/Name :/ { print $3; exit }')"
  [[ "$console_user" == "$USER" ]] || return 1

  session_state="$(/usr/sbin/ioreg -n Root -d1 2>/dev/null)" || return 1
  ! /usr/bin/grep -Eq 'CGSSessionScreenIsLocked[^,}]*Yes' <<< "$session_state"
}

attempt_pending_upgrade() {
  local attempted_tmp

  [[ -s "$PENDING_FILE" ]] || return
  if [[ -f "$ATTEMPTED_FILE" ]] && cmp -s "$PENDING_FILE" "$ATTEMPTED_FILE"; then
    return
  fi

  # Claim this nightly download before starting. If Homebrew fails, later
  # unlocks do not retry it; the next nightly fetch creates a new generation.
  attempted_tmp="$(mktemp "$STATE_DIR/attempted.XXXXXX")"
  cp "$PENDING_FILE" "$attempted_tmp"
  chmod 600 "$attempted_tmp"
  mv "$attempted_tmp" "$ATTEMPTED_FILE"

  install_pending_upgrades
}

watch_for_unlocked_session() {
  log "Homebrew login/unlock watcher started"

  while true; do
    if [[ -s "$PENDING_FILE" ]] && screen_is_unlocked; then
      attempt_pending_upgrade || true
    fi
    sleep 10
  done
}

install_pending_upgrades() {
  local install_manifest

  if [[ ! -s "$PENDING_FILE" ]]; then
    return
  fi

  install_manifest="$(mktemp "$STATE_DIR/install.XXXXXX")"
  cp "$PENDING_FILE" "$install_manifest"

  log "Homebrew upgrade started"
  export HOMEBREW_NO_AUTO_UPDATE=1

  if ! brew upgrade; then
    rm -f "$install_manifest"
    echo "==> Homebrew upgrade failed; it will not be retried until the next nightly download" >&2
    return 1
  fi

  # Do not erase a newer set downloaded while this installation was running.
  if cmp -s "$install_manifest" "$PENDING_FILE"; then
    rm -f "$PENDING_FILE" "$ATTEMPTED_FILE"
  fi
  rm -f "$install_manifest"
  log "Homebrew upgrade finished"
}

case "${1:-fetch}" in
  fetch) fetch_upgrades ;;
  watch) watch_for_unlocked_session ;;
  *)
    echo "Usage: $0 [fetch|watch]" >&2
    exit 2
    ;;
esac
