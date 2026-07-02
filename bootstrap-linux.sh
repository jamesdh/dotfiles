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

# Run ansible itself under sudo (as root) rather than relying on ansible's per-task
# become. Escalating inside ansible from this non-interactive context is fragile —
# depending on the VM's sudo/PAM setup it stalls with "interactive authentication
# is required" or a become timeout. Running the whole play as root sidesteps it
# (become: true then escalates root->root, which needs no password). We pass:
#   --vault-password-file  absolute, since ~ resolves to root's home under sudo
#   ssh_user               so GitHub keys land in the invoking user's account
#   tailscale_authkey/ssh  forwarded explicitly because sudo drops the environment
target_user="${USER:-$(id -un)}"
echo "==> Running the remote-access playbook as root (enter your sudo password if prompted)..."
sudo ansible-playbook --diff remote-access.yml \
  --vault-password-file "${vaultpass}" \
  -e "ssh_user=${target_user}" \
  -e "tailscale_authkey=${TS_AUTHKEY:-}" \
  -e "tailscale_ssh=${TS_SSH:-false}"

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
