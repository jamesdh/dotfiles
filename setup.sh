#!/bin/bash

echo "Checking for homebrew..."
[[ ! `brew config 2> /dev/null` ]] && echo "Installing Homebrew..." && yes '' | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

echo "Checking for mas..."
[[ ! `brew list mas 2> /dev/null` ]] && echo "Installing mas" && brew install mas

echo "Checking for ansible..."
[[ ! `brew list ansible 2> /dev/null` ]] && echo "Installing ansible" && brew install ansible

echo "Checking for lastpass..."
[[ ! `brew list lastpass-cli 2> /dev/null` ]] && echo "Installing lastpass-cli" && brew install lastpass-cli

echo "Checking App Store login status..."
# [[ ! `mas account 1> /dev/null` ]] && osascript -l JavaScript jxa/app_store.scpt 1> /dev/null && read -p "Please sign into the App Store to continue..."

echo "Installing apps requiring additional permissions prompts"
export HOMEBREW_CASK_OPTS='--no-quarantine'; brew bundle --file=roles/osx/files/Brewfile.preprompt

echo "Checking Accessibility status..."
[[ ! `osascript -l JavaScript jxa/access_check.scpt` ]] && echo "Re-run script after making necessary permissions changes!" && exit 1

ansible-playbook --ask-become-pass --diff --tags=preprompt ansible.yml

echo "Finished bootstrapping!"