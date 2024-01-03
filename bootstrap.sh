#!/bin/bash
set -e

echo "Checking for homebrew..."
[[ ! `brew config 2> /dev/null` ]] && echo "Installing Homebrew..." && /bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

if [ "$(arch)" = "arm64" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/usr/local/bin/brew shellenv)"
fi

echo "Checking for mas..."
[[ ! `brew list mas 2> /dev/null` ]] && echo "Installing mas" && brew install mas

echo "Preinstalling apps required for setup or requiring additional permissions prompts"
export HOMEBREW_CASK_OPTS='--no-quarantine'; brew bundle --file=roles/osx/files/Brewfile.preprompt

echo "Checking for vault password file..."
if [[ ! -f ~/.ansible/dotfiles_vaultpass ]]; then 
  make --no-print-directory login.op
  echo "Retrieving vault password"
  mkdir -p -m 0755 ~/.ansible
  touch ~/.ansible/dotfiles_vaultpass
  op item get "Ansible Vault - Dotfiles" --fields password --format json | jq --raw-output ".value" > ~/.ansible/dotfiles_vaultpass
fi

echo "Finished bootstrapping! Run \`make install\` to proceed."
echo ""
echo "To reduce the number of security prompts during install which can interrupt the install flow, first perform the following:"
echo "Go to..."
echo " - System Settings"
echo "   - Privacy & Security"
echo "     - Accessibility"
echo "       - Enable all shown applications"
echo "     - Full Disk Access"
echo "       - iTerm"
echo "       - Terminal"
echo "       - Visual Studio Code"
echo ""
