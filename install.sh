#!/bin/zsh
set -e

# If missing, install Xcode Command Line Developer Tools
xcode-select -p >& /dev/null || {
    xcode-select --install
    echo "Select \"Install\" for the prompted Command Line Developer Tools"
    osascript -e 'tell application "Install Command Line Developer Tools" to activate'
}

# If missing, install Rosetta 2
pkgutil --pkgs=com.apple.pkg.RosettaUpdateAuto >& /dev/null || {
    softwareupdate --install-rosetta --agree-to-license
}

# If missing, clone dotfiles locally
mkdir -p ~/Projects/jamesdh/dotfiles 
cd ~/Projects/jamesdh/dotfiles 
if [[ ! -d .git ]]; then
    git clone https://github.com/jamesdh/dotfiles.git . 
fi

source bootstrap.sh