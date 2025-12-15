#!/bin/zsh

# Prompt for sudo
sudo echo ""

# Function to check if com.apple.Terminal has Accessibility enabled
check_accessibility() {
    result=$(sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" \
        "SELECT auth_value FROM access WHERE service='kTCCServiceAccessibility' AND client='com.apple.Terminal';")
    # Return the value of result, indicating the status
    if [[ "$result" == "2" ]]; then
        return 0  # Accessibility is enabled
    else
        return 1  # Accessibility is not enabled
    fi
}

# Function to check if Terminal has Full Disk Access enabled
check_full_disk_access() {
    result=$(sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" \
        "SELECT auth_value FROM access WHERE service='kTCCServiceSystemPolicyAllFiles' AND client='com.apple.Terminal';")
    
    # Return 0 if Full Disk Access is enabled (auth_value is 1), otherwise return 1
    if [[ "$result" == "2" ]]; then
        return 0  # Full Disk Access is enabled
    else
        return 1  # Full Disk Access is not enabled
    fi
}

# Triggers the System Preferences -> Privacy & Security -> Full Disk Access and waits until 
# Terminal has been added and enabled
if ! check_full_disk_access; then
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
    while ! check_full_disk_access; do
        echo "Waiting for Full Disk Access for Terminal to be enabled..."
        sleep 1
    done
fi

# https://github.com/bvanpeski/SystemPreferences/blob/main/macos_preferencepanes-Ventura.md#privacy--security
# Triggers the System Preferences -> Privacy & Security -> Accessibility w/ Terminal already added
# and waits until permission has been enabled
if ! check_accessibility; then
    sudo osascript -e 'tell application "System Events" to click at {100, 100}' >& /dev/null
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    while ! check_accessibility; do
        echo "Waiting for Accessibility for Terminal to be enabled..."
        sleep 1
    done
fi

# Install Xcode Command Line Developer Tools if missing
# Get latest at https://developer.apple.com/download/all/
XCODE_CLI_FILENAME=Command_Line_Tools_for_Xcode_26.2.dmg
echo "Checking for Xcode Command Line Developer Tools..."
xcode-select -p >& /dev/null || {
    # If cache is present locally
    if [[ -f "/Volumes/SDXC/$XCODE_CLI_FILENAME" ]]; then
        echo "Waiting for Xcode Command Line Tools to finish installing..."
        hdiutil attach "/Volumes/SDXC/$XCODE_CLI_FILENAME" -quiet
        sudo installer -pkg /Volumes/Command\ Line\ Developer\ Tools/Command\ Line\ Tools.pkg -target /
        hdiutil detach /Volumes/Command\ Line\ Developer\ Tools -quiet
    # If cache is shared with Parallels
    elif [[ -f "/Volumes/My Shared Files/SDXC/$XCODE_CLI_FILENAME" ]]; then
        echo "Waiting for Xcode Command Line Tools to finish installing..."
        hdiutil attach "/Volumes/My\ Shared\ Files/SDXC/$XCODE_CLI_FILENAME" -quiet
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
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOMEBREW_PREFIX/bin:$PATH"

# If an attached external disk contains the cache, use that
if [[ -d /Volumes/SDXC/Homebrew ]]; then
  export HOMEBREW_CACHE=/Volumes/SDXC/Homebrew
fi

# Install all apps that are immediately required for bootstrapping. 
echo "Checking for required apps..."
export HOMEBREW_CASK_OPTS='--no-quarantine'; brew bundle --file=roles/osx/files/Brewfile.bootstrap

# If 1Password does not have CLI integration enabled, prompt and wait for it
echo "Checking for 1Password CLI integration..."
output=$(op whoami 2>&1)
if [[ "$output" == *"no account found"* ]]; then
  echo "Sign in to 1Password, then enable CLI integration in Settings -> Developer -> Command-Line Interface"
  open -a "/Applications/1Password.app"
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
pyenv install
python -m venv venv
source venv/bin/activate
pip install -q -r requirements.txt

echo ""
echo " Do not change from default resolution until after setup is complete."
echo ""
echo "Next:"
echo "- Run \`make install.priority\` to install the essentials."
echo "- Run \`make install.nonpriority\` to install everything else."
echo "- Run \`make install\` to install everything at once."
echo ""
