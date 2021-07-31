#!/bin/bash

echo "Checking for homebrew..."
[[ ! `brew config 2> /dev/null` ]] && echo "Installing Homebrew..." && /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "Checking for mas..."
[[ ! `brew list mas 2> /dev/null` ]] && echo "Installing mas" && brew install mas

echo "Checking App Store login status..."
make login.appstore

echo "Preinstalling apps required for setup or requiring additional permissions prompts"
export HOMEBREW_CASK_OPTS='--no-quarantine'; brew bundle --file=roles/osx/files/Brewfile.preprompt

echo "Checking for vault password file..."
if [[ ! -f ~/.ansible/dotfiles_vaultpass ]]; then 
  eval $(make login.op)
  echo "Retrieving vault password"
  mkdir -p -m 0755 ~/.ansible
  touch ~/.ansible/dotfiles_vaultpass
  op get item "Ansible Vault - Dotfiles" --fields password > ~/.ansible/dotfiles_vaultpass
fi

echo "Finished bootstrapping! Run \`make install\` to proceed."
echo ""
echo "To reduce the number of security prompts during install which can interrupt the install flow, first perform the following:"
echo "Go to..."
echo " - System Preferences"
echo "   - Security & Privacy"
echo "     - Privacy"
echo "       - Accessibility"
echo "         - Enable all shown applications"
echo "       - Full Disk Access"
echo "         - Enable Terminal + iTerm"
echo ""