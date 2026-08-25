#!/bin/bash
# Two-stage Homebrew upgrades:
#   fetch   downloads outdated packages at 02:00 without installing them;
#   watch   waits for an unlocked GUI session and opens the installer in Terminal;
#   install requests sudo/Touch ID and installs exactly the fetched package set.
set -euo pipefail

export PATH="/opt/homebrew/bin:/usr/bin:/bin"
export HOMEBREW_NO_ASK=1
export HOMEBREW_NO_ENV_HINTS=1

STATE_DIR="$HOME/Library/Caches/com.jamesdh.brew-upgrade"
PENDING_FILE="$STATE_DIR/pending"
PROMPTED_FILE="$STATE_DIR/prompted"
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
    rm -f "$PENDING_FILE" "$PROMPTED_FILE"
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

prompt_for_pending_upgrade() {
  local prompted_tmp

  [[ -s "$PENDING_FILE" ]] || return
  if [[ -f "$PROMPTED_FILE" ]] && cmp -s "$PENDING_FILE" "$PROMPTED_FILE"; then
    return
  fi

  prompted_tmp="$(mktemp "$STATE_DIR/prompted.XXXXXX")"
  cp "$PENDING_FILE" "$prompted_tmp"
  chmod 600 "$prompted_tmp"
  mv "$prompted_tmp" "$PROMPTED_FILE"

  if ! /usr/bin/osascript - "$SCRIPT_PATH" >/dev/null <<'APPLESCRIPT'
on run argv
  set installCommand to (quoted form of (item 1 of argv)) & " install"
  tell application "Terminal"
    activate
    do script installCommand
  end tell
end run
APPLESCRIPT
  then
    echo "==> Failed to open the Homebrew upgrade in Terminal" >&2
    return 1
  fi

  log "Opened the pending Homebrew upgrade in Terminal"
}

watch_for_unlocked_session() {
  log "Homebrew login/unlock watcher started"

  while true; do
    if [[ -s "$PENDING_FILE" ]] && screen_is_unlocked; then
      prompt_for_pending_upgrade || true
    fi
    sleep 10
  done
}

probe_app_management_permission() {
  local brew_ruby="/opt/homebrew/Library/Homebrew/vendor/portable-ruby/current/bin/ruby"

  # Upgrading casks in place needs macOS App Management permission. Probe while
  # the user is present so its one-time prompt cannot be stranded overnight.
  if [[ -x "$brew_ruby" && -d /Applications/iTerm.app ]]; then
    "$brew_ruby" -e '
      probe = "/Applications/iTerm.app/.brew-upgrade-tcc-probe"
      begin
        File.write(probe, "")
        File.delete(probe)
      rescue SystemCallError
      end
    ' || true
  fi
}

install_pending_upgrades() {
  local kind package install_manifest failed=0
  local -a formulae=()
  local -a casks=()

  if [[ ! -s "$PENDING_FILE" ]]; then
    echo "No downloaded Homebrew upgrades are pending."
    return
  fi

  install_manifest="$(mktemp "$STATE_DIR/install.XXXXXX")"
  cp "$PENDING_FILE" "$install_manifest"

  while IFS=$'\t' read -r kind package; do
    case "$kind" in
      formula) [[ -n "$package" ]] && formulae+=("$package") ;;
      cask) [[ -n "$package" ]] && casks+=("$package") ;;
    esac
  done < "$install_manifest"

  if (( ${#formulae[@]} == 0 && ${#casks[@]} == 0 )); then
    echo "No downloaded Homebrew upgrades are pending."
    rm -f "$install_manifest"
    return
  fi

  echo "Downloaded Homebrew upgrades are ready to install."
  echo "Authenticate with sudo/Touch ID to continue."
  if ! sudo -v; then
    rm -f "$install_manifest"
    return 1
  fi

  probe_app_management_permission
  export HOMEBREW_NO_AUTO_UPDATE=1

  if (( ${#formulae[@]} > 0 )); then
    brew upgrade --formula "${formulae[@]}" || failed=1
  fi
  if (( ${#casks[@]} > 0 )); then
    brew upgrade --cask "${casks[@]}" || failed=1
  fi

  if (( failed != 0 )); then
    rm -f "$install_manifest"
    echo
    echo "One or more Homebrew upgrades failed. The pending set was preserved."
    read -r -p "Press Return to close this window..." || true
    return 1
  fi

  # Do not erase a newer set downloaded while this installation was running.
  if cmp -s "$install_manifest" "$PENDING_FILE"; then
    rm -f "$PENDING_FILE" "$PROMPTED_FILE"
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
