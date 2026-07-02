# dotfiles
Sensible and consistent OS defaults, but to an extreme ¯\_(ツ)_/¯ 

### Getting started
`source <(curl -H "Cache-Control: no-cache" -s https://raw.githubusercontent.com/jamesdh/dotfiles/master/bootstrap.sh)`

### Headless Linux VM (remote access)
Provision a fresh Ubuntu VM for remote access over Tailscale + SSH — installs Tailscale, enables SSH, imports your GitHub public keys, and hardens `sshd` to key-only auth. Run locally on the VM:

`bash <(curl -fsSL https://raw.githubusercontent.com/jamesdh/dotfiles/master/bootstrap-linux.sh)`

To join the tailnet non-interactively, pass a [Tailscale auth key](https://tailscale.com/kb/1085/auth-keys):

`TS_AUTHKEY=tskey-... bash <(curl -fsSL https://raw.githubusercontent.com/jamesdh/dotfiles/master/bootstrap-linux.sh)`