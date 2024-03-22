#!/bin/zsh

# Install Xcode Command Line Developer Tools if missing
echo "Checking for Xcode Command Line Developer Tools..."
xcode-select -p >& /dev/null || {
    if [[ -f /Volumes/SDXC/Command_Line_Tools_for_Xcode_15.3.dmg ]]; then
        echo "Waiting for Xcode Command Line Tools to finish installing..."
        hdiutil attach /Volumes/SDXC/Command_Line_Tools_for_Xcode_15.3.dmg -quiet
        sudo installer -pkg /Volumes/Command\ Line\ Developer\ Tools/Command\ Line\ Tools.pkg -target /
        hdiutil detach /Volumes/Command\ Line\ Developer\ Tools -quiet
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

# Install Rosetta 2 if missing
echo "Checking for Rosetta 2..."
pkgutil --pkgs=com.apple.pkg.RosettaUpdateAuto >& /dev/null || {
    softwareupdate --install-rosetta --agree-to-license
}

# Clone dotfiles locally if missing
mkdir -p ~/Projects/jamesdh/dotfiles 
cd ~/Projects/jamesdh/dotfiles 
if [[ ! -d .git ]]; then
    echo "Cloning dotfiles locally..."
    git clone https://github.com/jamesdh/dotfiles.git . 
fi

# Install Homebrew if missing
echo "Checking for homebrew..."
if ! brew config >& /dev/null; then 
  if [[ ! -f /opt/homebrew/bin/brew ]]; then
    echo "Installing Homebrew..." 
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null 
  fi
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

# If an attached external disk contains the cache, use that
if [[ -d /Volumes/SDXC/Homebrew ]]; then
  export HOMEBREW_CACHE=/Volumes/SDXC/Homebrew
fi

# Install all apps that are immediately required for bootstrapping. 
echo "Checking for required apps..."
export HOMEBREW_CASK_OPTS='--no-quarantine'; brew bundle --file=roles/osx/files/Brewfile.bootstrap
# HOMEBREW_CASK_OPTS='--no-quarantine'; brew bundle -q --file=roles/osx/files/Brewfile.bootstrap --no-lock | grep "Installing" || true

# If 1Password does not have CLI integration enabled, prompt and wait for it
echo "Checking for 1Password CLI integration..."
output=$(op whoami 2>&1)
if [[ "$output" == *"no account found"* ]]; then
  echo "Sign in to 1Password, then enable CLI integration in Settings -> Developer -> Command-Line Interface"
  open -a "1Password"
  output=$(op whoami 2>&1)
  while [[ "$output" == *"no account found"* ]]; do
    echo "Waiting for 1Password CLI integration to be enabled..."
    sleep 5
    output=$(op whoami 2>&1)
  done
fi

# Restore Ansible vaultpass via 1Password if missing
echo "Checking for vault password file..."
if [[ ! -f ~/.ansible/dotfiles_vaultpass ]]; then
  echo "Retrieving vault password"
  mkdir -p -m 0755 ~/.ansible
  touch ~/.ansible/dotfiles_vaultpass
  op item get "Ansible Vault - Dotfiles" --fields password --format json | jq --raw-output ".value" > ~/.ansible/dotfiles_vaultpass
fi

# Install python environment to run ansible
echo "Checking python environment..."
eval "$(pyenv init -)"
python3 -m venv venv
source venv/bin/activate
pip install -q -r requirements.txt

echo ""
echo "Finished bootstrapping!"
echo ""
echo "Run \`make install.priority\` then restart to install the essentials."
echo "Run \`make install.nonpriority\` to install everything else."
echo "Or just run \`make install\` to install everything at once."
echo ""
