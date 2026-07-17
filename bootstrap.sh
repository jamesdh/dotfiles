#!/bin/zsh

# Prompt for sudo — and fail fast if sudo itself is broken, instead of letting the
# Full Disk Access wait below spin forever on a check that can never succeed.
# (Known brick: /etc/pam.d/sudo referencing pam_reattach.so while pam-reattach isn't
# installed — see roles/osx/tasks/auth.yml.)
if ! sudo true; then
    cat <<'EOF'

ERROR: sudo is failing before bootstrap can start. If the message above says
"unable to initialize PAM", then /etc/pam.d/sudo references a PAM module that is
not installed (usually pam_reattach.so). Repair it with:

  osascript -e 'do shell script "sed -i \"\" \"/pam_reattach/d; /pam_tid/d\" /etc/pam.d/sudo" with administrator privileges'

then re-run this bootstrap.
EOF
    return 1 2>/dev/null || exit 1
fi

# Return 0 if <bundle_id> (arg 2) is granted <service> (arg 1) in the system TCC.db.
# auth_value 2 = allowed; a denied row or no row both count as not granted.
tcc_granted() {
    local service="$1" bundle="$2"
    [[ "$(sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" \
        "SELECT auth_value FROM access WHERE service='$service' AND client='$bundle';")" == "2" ]]
}

# Open a Privacy pane and block until <bundle_id> is granted <service>. The grant is manual:
# add the app with the pane's "+" if it isn't listed, then switch it on.
# Args: <service> <bundle_id> <pane_anchor> <label>
wait_for_tcc() {
    local service="$1" bundle="$2" anchor="$3" label="$4"
    if ! tcc_granted "$service" "$bundle"; then
        open "x-apple.systempreferences:com.apple.preference.security?$anchor"
        while ! tcc_granted "$service" "$bundle"; do
            echo "Waiting for $label to be enabled..."
            sleep 1
        done
    fi
}

# Terminal hosts this bootstrap: grant it Full Disk Access (to read TCC state) and
# Accessibility (for UI automation) before the ansible run needs them.
wait_for_tcc kTCCServiceSystemPolicyAllFiles com.apple.Terminal Privacy_AllFiles "Full Disk Access for Terminal"

# https://github.com/bvanpeski/SystemPreferences/blob/main/macos_preferencepanes-Ventura.md#privacy--security
if ! tcc_granted kTCCServiceAccessibility com.apple.Terminal; then
    # Poke System Events so Terminal is added to the Accessibility list up front, leaving
    # only the toggle for the user.
    sudo osascript -e 'tell application "System Events" to click at {100, 100}' >& /dev/null
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    while ! tcc_granted kTCCServiceAccessibility com.apple.Terminal; do
        echo "Waiting for Accessibility for Terminal to be enabled..."
        sleep 1
    done
fi

# Install Xcode Command Line Developer Tools if missing
# Get latest at https://developer.apple.com/download/all/
XCODE_CLI_FILENAME=Command_Line_Tools_26.6_Apple_silicon.dmg
echo "Checking for Xcode Command Line Developer Tools..."
xcode-select -p >& /dev/null || {
    # Look for a cached installer dmg on an attached external drive (T7 SSD
    # preferred, SDXC card as fallback), including their Parallels shares.
    XCODE_CLI_DMG=""
    for vol in "/Volumes/T7" "/Volumes/SDXC" "/Volumes/My Shared Files/T7" "/Volumes/My Shared Files/SDXC"; do
        if [[ -f "$vol/$XCODE_CLI_FILENAME" ]]; then
            XCODE_CLI_DMG="$vol/$XCODE_CLI_FILENAME"
            break
        fi
    done

    if [[ -n "$XCODE_CLI_DMG" ]]; then
        echo "Installing Xcode Command Line Tools from $XCODE_CLI_DMG..."
        hdiutil attach "$XCODE_CLI_DMG" -quiet
        sudo installer -pkg "/Volumes/Command Line Developer Tools/Command Line Tools.pkg" -target /
        hdiutil detach "/Volumes/Command Line Developer Tools" -quiet
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

# If an attached external disk should hold the cache, use it. Prefer the T7 SSD
# (kept connected across reinstalls); create its Homebrew dir so the cache
# self-populates on a fresh setup. Fall back to the SDXC card if its cache exists.
if [[ -d /Volumes/T7 ]]; then
  mkdir -p /Volumes/T7/Homebrew
  export HOMEBREW_CACHE=/Volumes/T7/Homebrew
elif [[ -d /Volumes/SDXC/Homebrew ]]; then
  export HOMEBREW_CACHE=/Volumes/SDXC/Homebrew
fi

# Install all apps that are immediately required for bootstrapping. 
echo "Checking for required apps..."
brew bundle --file=roles/osx/files/Brewfile.bootstrap

# Homebrew 6 always quarantines cask apps (no more --no-quarantine), so strip the
# xattr right away — 1Password is opened later in this bootstrap for the vault
# password and must launch without a Gatekeeper prompt. jq arrives in the bundle above.
brew info --cask --json=v2 --installed |
  jq -r '.casks[].artifacts[] | select(.app) | .target // ("/Applications/" + .app[0])' |
  while IFS= read -r app; do
    if [[ -d "$app" ]] && xattr -p com.apple.quarantine "$app" >/dev/null 2>&1; then
      xattr -dr com.apple.quarantine "$app"
      echo "Removed quarantine: $app"
    fi
  done

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

# Same grants for iTerm, in case `make install` is run from it rather than Terminal. iTerm
# isn't pre-listed in either pane and can't be poked into the Accessibility list from this
# Terminal-hosted script, so add it with the pane's "+" when it opens.
if [[ -d /Applications/iTerm.app ]]; then
    wait_for_tcc kTCCServiceSystemPolicyAllFiles com.googlecode.iterm2 Privacy_AllFiles "Full Disk Access for iTerm"
    wait_for_tcc kTCCServiceAccessibility com.googlecode.iterm2 Privacy_Accessibility "Accessibility for iTerm"
else
    echo "WARNING: iTerm.app not found; skipping its Full Disk Access / Accessibility setup."
fi

echo ""
echo " Do not change from default resolution until after setup is complete."
echo ""
echo "Next:"
echo "- Run \`make install.priority\` to install the essentials."
echo "- Run \`make install.nonpriority\` to install everything else."
echo "- Run \`make install\` to install everything at once."
echo ""
