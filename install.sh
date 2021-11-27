xcode-select --install
softwareupdate --install-rosetta
mkdir -p ~/Projects/jamesdh/dotfiles 
cd ~/Projects/jamesdh/dotfiles 
git clone https://github.com/jamesdh/dotfiles.git . 
source bootstrap.sh