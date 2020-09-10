#!/bin/bash

authenticate() {
  if [[ ! `op list users 2> /dev/null` ]]; then
    eval $(op signin my)
  fi
}

echo "Checking for homebrew..."
[[ ! `brew config 2> /dev/null` ]] && echo "Installing Homebrew..." && yes '' | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

echo "Checking for mas..."
[[ ! `brew list mas 2> /dev/null` ]] && echo "Installing mas" && brew install mas

echo "Checking for ansible..."
[[ ! `brew list ansible 2> /dev/null` ]] && echo "Installing ansible" && brew install ansible

echo "Checking for 1password..."
[[ ! `brew cask list 1password-cli 2> /dev/null` ]] && echo "Installing 1password-cli" && brew cask install 1password-cli

echo "Checking 1password initial login status..."
make login.op

# echo "Checking App Store login status..."
# # [[ ! `mas account 1> /dev/null` ]] && osascript -l JavaScript jxa/app_store.scpt 1> /dev/null && read -p "Please sign into the App Store to continue..."

echo "Installing apps requiring additional permissions prompts"
export HOMEBREW_CASK_OPTS='--no-quarantine'; brew bundle --file=roles/osx/files/Brewfile.preprompt

echo "Checking Accessibility status..."
[[ ! `osascript -l JavaScript jxa/access_check.scpt` ]] && echo "Re-run script after making necessary permissions changes!" && exit 1

echo "Checking for vault password file..."
if [[ ! -f ~/.ansible/dotfiles_vaultpass ]]; then 
  echo "Retrieving vault password"
  mkdir -p -m 0755 ~/.ansible
  touch ~/.ansible/dotfiles_vaultpass
  authenticate
  op get item "Ansible Vault - Dotfiles" --fields password > ~/.ansible/dotfiles_vaultpass
fi

# ansible-playbook --ask-become-pass --diff --skip-tags "postinstall" ansible.yml
# ansible-playbook --ask-become-pass --diff --tags "postinstall" ansible.yml

echo "Finished bootstrapping!"