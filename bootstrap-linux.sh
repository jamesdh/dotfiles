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

# Always ask for the become (sudo) password; press Enter if this VM has
# passwordless sudo. Auto-detecting passwordless sudo is unreliable — the sudo
# timestamp primed by the apt step above is scoped to this shell's terminal and
# does not carry into ansible's separate sudo session, so `sudo -n` here can't
# predict whether ansible's become will need a password.
echo "==> Running the remote-access playbook."
echo "    Enter your sudo password when prompted (press Enter if sudo is passwordless)."
ansible-playbook --diff remote-access.yml --ask-become-pass

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
