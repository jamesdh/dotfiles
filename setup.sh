#!/bin/bash

echo "Checking for pip..."
[[ ! `pip list 2> /dev/null` ]] && echo "Installing pip" && sudo easy_install pip

echo "Checking for ansible..."
[[ ! `pip list` =~ "ansible" ]] && echo "Installing ansible" && sudo -H pip install ansible --quiet

echo "Checking for homebrew..."
[[ ! `brew config 2> /dev/null` ]] && echo "Installing Homebrew..." && yes '' | ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

echo "Checking for lastpass..."
[[ ! `brew list lastpass-cli 2> /dev/null` ]] && echo "Installing lastpass-cli" && brew install lastpass-cli
