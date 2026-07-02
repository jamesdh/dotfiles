#!/usr/bin/env bash
#
# Bootstrap a fresh, headless Ubuntu VM for remote access (Tailscale + SSH).
#
# Run locally on the VM:
#   bash <(curl -fsSL https://raw.githubusercontent.com/jamesdh/dotfiles/master/bootstrap-linux.sh)
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

echo "==> Cloning dotfiles into ${REPO_DIR}..."
mkdir -p "${REPO_DIR}"
if [[ ! -d "${REPO_DIR}/.git" ]]; then
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

# Only prompt for a sudo password if this host actually needs one. Many cloud
# images grant the first user passwordless sudo, and the apt step above already
# primed the sudo timestamp.
become_args=()
if ! sudo -n true 2>/dev/null; then
  become_args=(--ask-become-pass)
fi

echo "==> Running the remote-access playbook..."
ansible-playbook --diff remote-access.yml "${become_args[@]}"

# The playbook joins the tailnet non-interactively when TS_AUTHKEY is set. If the
# node still isn't connected (no key, or the key was rejected), fall back to the
# interactive login URL here, where a human is watching the terminal.
ts_ssh_flag=()
case "${TS_SSH:-}" in
  1 | true | yes | on) ts_ssh_flag=(--ssh) ;;
esac

if ! tailscale status >/dev/null 2>&1; then
  echo "==> Authorize this node on your tailnet — open the URL below in a browser:"
  sudo tailscale up "${ts_ssh_flag[@]}"
fi

echo
if tailscale status >/dev/null 2>&1; then
  ts_ip="$(tailscale ip -4 2>/dev/null | head -n1)"
  echo "==> Done. This node is on your tailnet at ${ts_ip}."
  echo "    SSH from another tailnet device:  ssh ${USER:-$(id -un)}@${ts_ip}"
else
  echo "==> Done, but Tailscale isn't connected yet. Run: sudo tailscale up"
fi
