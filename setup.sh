#!/bin/bash

echo "Checking for homebrew..."
[[ ! `brew config 2> /dev/null` ]] && echo "Installing Homebrew..." && yes '' | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

echo "Checking for ansible..."
[[ ! `brew list ansible 2> /dev/null` ]] && echo "Installing ansible" && brew install ansible

echo "Checking for lastpass..."
[[ ! `brew list lastpass-cli 2> /dev/null` ]] && echo "Installing lastpass-cli" && brew install lastpass-cli
