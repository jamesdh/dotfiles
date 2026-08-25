#!/bin/bash
# Two-stage Homebrew upgrades:
#   fetch   downloads outdated packages at 02:00 without installing them;
#   watch   sends one actionable notification when the GUI session is unlocked;
#   install runs the pending upgrade when that notification is clicked.
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/bin:/bin"
export HOMEBREW_NO_ASK=1
export HOMEBREW_NO_ENV_HINTS=1

STATE_DIR="$HOME/Library/Caches/com.jamesdh.brew-upgrade"
PENDING_FILE="$STATE_DIR/pending"
NOTIFIED_FILE="$STATE_DIR/notified"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/$(basename "$0")"

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
    rm -f "$PENDING_FILE" "$NOTIFIED_FILE"
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

notify_pending_upgrade() {
  local execute_command notified_tmp

  [[ -s "$PENDING_FILE" ]] || return
  if [[ -f "$NOTIFIED_FILE" ]] && cmp -s "$PENDING_FILE" "$NOTIFIED_FILE"; then
    return
  fi

  if ! command -v grrr >/dev/null; then
    echo "==> Growlrrr is unavailable; cannot offer the pending Homebrew upgrade" >&2
    return 1
  fi

  # Growlrrr executes notification actions with `/bin/sh -c`. Use the script's
  # absolute path so the action keeps the same cache and pending-state behavior.
  printf -v execute_command '%q install >> %q 2>&1' \
    "$SCRIPT_PATH" "$HOME/Library/Logs/brew-upgrade.log"

  grrr send \
    --title "Homebrew updates ready" \
    --subtitle "Downloaded overnight" \
    --sound default \
    --identifier homebrew-upgrade \
    --replace \
    --execute "$execute_command" \
    "Click to install the downloaded updates."

  notified_tmp="$(mktemp "$STATE_DIR/notified.XXXXXX")"
  cp "$PENDING_FILE" "$notified_tmp"
  chmod 600 "$notified_tmp"
  mv "$notified_tmp" "$NOTIFIED_FILE"
  log "Sent the pending Homebrew upgrade notification"
}

watch_for_unlocked_session() {
  log "Homebrew login/unlock watcher started"

  while true; do
    if [[ -s "$PENDING_FILE" ]] && screen_is_unlocked; then
      notify_pending_upgrade || true
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
    echo "==> Homebrew upgrade failed; the pending set was preserved" >&2
    return 1
  fi

  # Do not erase a newer set downloaded while this installation was running.
  if cmp -s "$install_manifest" "$PENDING_FILE"; then
    rm -f "$PENDING_FILE" "$NOTIFIED_FILE"
  fi
  rm -f "$install_manifest"
  log "Homebrew upgrade finished"
}

case "${1:-fetch}" in
  fetch) fetch_upgrades ;;
  watch) watch_for_unlocked_session ;;
  install) install_pending_upgrades ;;
  *)
    echo "Usage: $0 [fetch|watch|install]" >&2
    exit 2
    ;;
esac
