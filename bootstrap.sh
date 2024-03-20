#!/bin/zsh
set -e

echo "Checking for homebrew..."
if ! brew config >& /dev/null; then 
  if [[ ! -f /opt/homebrew/bin/brew ]]; then
    echo "Installing Homebrew..." 
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

echo "Checking for 1Password..."
if ! brew list | grep -q "1password"; then
  echo "Installing 1Password..."
  brew install 1password 1password-cli
fi
set +e
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
set -e

echo "Checking for vault password file..."
if [[ ! -f ~/.ansible/dotfiles_vaultpass ]]; then
  echo "Retrieving vault password"
  mkdir -p -m 0755 ~/.ansible
  touch ~/.ansible/dotfiles_vaultpass
  op item get "Ansible Vault - Dotfiles" --fields password --format json | jq --raw-output ".value" > ~/.ansible/dotfiles_vaultpass
fi

echo "Checking for mas..."
if ! brew list mas >& /dev/null; then
  echo "Installing mas"
  brew install mas
fi

echo "Checking for required apps..."
export HOMEBREW_CASK_OPTS='--no-quarantine'
brew bundle -q --file=roles/osx/files/Brewfile.preprompt --no-lock | grep "Installing" || true

echo "Checking for python environment..."
eval "$(pyenv init -)"
python3 -m venv venv
source venv/bin/activate
pip install -q -r requirements.txt

echo ""
echo "Finished bootstrapping! Run \`make install\` to proceed."
echo ""
echo "To reduce the number of security prompts during install which can interrupt the install flow, first perform the following:"
echo "Go to..."
echo " - System Settings"
echo "   - Privacy & Security"
echo "     - Accessibility"
echo "       - Enable all shown applications"
echo "     - Full Disk Access"
echo "       - iTerm"
echo "       - Terminal"
echo "       - Visual Studio Code"
echo ""
