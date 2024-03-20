#!/bin/zsh
set -e

# If missing, install Xcode Command Line Developer Tools
xcode-select -p >& /dev/null || {
    if [[ -f /Volumes/SDXC/Command_Line_Tools_for_Xcode_15.3.dmg ]]; then
        echo "Waiting for Xcode Command Line Tools to finish installing..."
        hdiutil attach /Volumes/SDXC/Command_Line_Tools_for_Xcode_15.3.dmg
        sudo installer -pkg /Volumes/Command\ Line\ Developer\ Tools/Command\ Line\ Tools.pkg -target /
        hdiutil detach /Volumes/Command\ Line\ Developer\ Tools
    else
        xcode-select --install
        echo "Select \"Install\" when prompted for Command Line Developer Tools"
        sleep 3
        osascript -e 'tell application "Install Command Line Developer Tools" to activate'
        while ! pkgutil --pkg-info=com.apple.pkg.CLTools_Executables &>/dev/null; do
            echo "Waiting for Xcode Command Line Tools to finish installing..."
            sleep 5
        done
    fi
    echo "Xcode Command Line Tools are installed."
}

# If missing, install Rosetta 2
pkgutil --pkgs=com.apple.pkg.RosettaUpdateAuto >& /dev/null || {
    softwareupdate --install-rosetta --agree-to-license
}

# If missing, clone dotfiles locally
mkdir -p ~/Projects/jamesdh/dotfiles 
cd ~/Projects/jamesdh/dotfiles 
if [[ ! -d .git ]]; then
    echo "Cloning dotfiles locally..."
    git clone https://github.com/jamesdh/dotfiles.git . 
fi

# If Homebrew cache doesn't exist locally, and an external drive is connected
# that contains it, copy it over
if [[ ! -d ~/Library/Caches/Homebrew ]]; then
    if [[ -d /Volumes/SDXC/Homebrew ]]; then
        echo "Copying Homebrew Cache locally..."
        rsync -aP /Volumes/SDXC/Homebrew ~/Library/Caches/Homebrew
    fi
fi

source bootstrap.sh