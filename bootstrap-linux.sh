#!/usr/bin/env bash
#
# Bootstrap a fresh, headless Ubuntu VM for remote access (Tailscale + SSH).
#
# Run locally on the VM (no-cache defeats the ~5 min raw.githubusercontent CDN cache,
# so a just-pushed fix is never skipped):
#   bash <(curl -fsSL -H "Cache-Control: no-cache" https://raw.githubusercontent.com/jamesdh/dotfiles/master/bootstrap-linux.sh)
#
# Join the tailnet non-interactively with a pre-generated auth key:
#   TS_AUTHKEY=tskey-... bash <(curl -fsSL .../bootstrap-linux.sh)
#
# Also enable Tailscale SSH:
#   TS_SSH=1 bash <(curl -fsSL .../bootstrap-linux.sh)
#
set -euo pipefail

REPO_URL="https://github.com/jamesdh/dotfiles.git"
REPO_DIR="${HOME}/Projects/jamesdh/dotfiles"

echo "==> Installing prerequisites (ansible, git, curl)..."
sudo apt-get update
sudo apt-get install -y ansible git curl

# Ubuntu's ansible bundle ships an older ansible.posix whose authorized_key module
# imports from deprecated module_utils paths (deprecation warnings on core 2.19+,
# removal in 2.24). Upstream fixed the imports in 2.2.1 — install it user-level,
# which takes precedence over the apt-bundled copy.
echo "==> Updating the ansible.posix collection..."
ansible-galaxy collection install 'ansible.posix>=2.2.1' --upgrade

# Clone the repo, or force an existing clone to match origin/master so re-running
# this one-liner always provisions with the latest pushed config. (The bootstrap
# script itself is fetched fresh from raw-GitHub, but the repo it runs is not.)
echo "==> Fetching dotfiles into ${REPO_DIR}..."
if [[ -d "${REPO_DIR}/.git" ]]; then
  git -C "${REPO_DIR}" fetch --quiet origin
  git -C "${REPO_DIR}" reset --hard --quiet origin/master
else
  mkdir -p "${REPO_DIR}"
  git clone "${REPO_URL}" "${REPO_DIR}"
fi
cd "${REPO_DIR}"

# The repo's ansible.cfg sets vault_password_file=~/.ansible/dotfiles_vaultpass and
# ansible loads it at startup. The desktop bootstrap fills it with the real vault
# password from 1Password (the macOS playbook decrypts vault files); this playbook
# is vault-free, so on a headless VM we just drop a placeholder to satisfy ansible —
# it is loaded but never used to decrypt anything.
vaultpass="${HOME}/.ansible/dotfiles_vaultpass"
if [[ ! -f "${vaultpass}" ]]; then
  mkdir -p "${HOME}/.ansible"
  printf 'unused-on-headless-vm\n' >"${vaultpass}"
  chmod 600 "${vaultpass}"
fi

# Escalate the idiomatic way: run as this user and let ansible `become` root per
# task. One wrinkle — Ubuntu 25.10+ defaults to sudo-rs, which doesn't implement
# the -p prompt flag ansible uses to detect the sudo password prompt, so become
# hangs and times out. Classic sudo still ships alongside it as `sudo.ws`; point
# ansible's become at that when present (older releases use the default sudo).
become_exe_args=()
if sudo_ws="$(command -v sudo.ws 2>/dev/null)"; then
  echo "==> Detected sudo-rs; using classic sudo (${sudo_ws}) for ansible become."
  become_exe_args=(-e "ansible_become_exe=${sudo_ws}")
fi
echo "==> Running the remote-access playbook."
echo "    Enter your sudo password when prompted (press Enter if sudo is passwordless)."
ansible-playbook --diff remote-access.yml --ask-become-pass "${become_exe_args[@]}"

# The playbook joins the tailnet non-interactively when TS_AUTHKEY is set. If the
# node still isn't connected (no key, or the key was rejected), fall back to the
# interactive login URL here, where a human is watching the terminal.
ts_ssh_flag=()
case "${TS_SSH:-}" in
  1 | true | yes | on) ts_ssh_flag=(--ssh) ;;
esac

if ! sudo tailscale status >/dev/null 2>&1; then
  echo "==> Authorize this node on your tailnet — open the URL below in a browser:"
  sudo tailscale up "${ts_ssh_flag[@]}"
fi

echo
if sudo tailscale status >/dev/null 2>&1; then
  ts_ip="$(sudo tailscale ip -4 2>/dev/null | head -n1)"
  echo "==> Done. This node is on your tailnet at ${ts_ip}."
  echo "    SSH from another tailnet device:  ssh ${USER:-$(id -un)}@${ts_ip}"
else
  echo "==> Done, but Tailscale isn't connected yet. Run: sudo tailscale up"
fi
