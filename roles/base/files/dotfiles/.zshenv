# https://unix.stackexchange.com/questions/71253/what-should-shouldnt-go-in-zshenv-zshrc-zlogin-zprofile-zlogout
# .zshenv → .zprofile → .zshrc → .zlogin → .zlogout

export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# Prevents Pure from checking whether the current Git remote has been updated
export PURE_GIT_PULL=0

# Exports HOMEBREW_PREFIX and updates the PATH to the appropriate Homebrew bin location
eval "$(/opt/homebrew/bin/brew shellenv)"
export HOMEBREW_CASK_OPTS='--no-quarantine'
# If an attached external disk contains the cache, use that
if [[ -d /Volumes/SDXC/Homebrew ]]; then
    export HOMEBREW_CACHE=/Volumes/SDXC/Homebrew
fi

# Needed for Krew (kubernetes)
export KREW_BIN="${HOME}/.krew/bin"
export PATH="$PATH:$KREW_BIN"

# JetBrains Toolbox (CLI tools)
export PATH="/Users/jamesdh/Library/Application Support/JetBrains/Toolbox/scripts:$PATH"

# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/jamesdh/.cache/lm-studio/bin"

# Claude Code
export PATH="$HOME/.local/bin:$PATH"

# Make vim the default editor.
export EDITOR='vim';

# Make Python use UTF-8 encoding for output to stdin, stdout, and stderr.
export PYTHONIOENCODING='UTF-8';

# Increase Bash history size. Allow 32³ entries; the default is 500.
export HISTSIZE='32768';
export HISTFILESIZE="${HISTSIZE}";
# Omit duplicates and commands that begin with a space from history.
export HISTCONTROL='ignoreboth';

# Prefer US English and use UTF-8.
export LANG='en_US.UTF-8';
export LC_ALL='en_US.UTF-8';

# Highlight section titles in manual pages.
export LESS_TERMCAP_md="${yellow}";

# Avoid issues with `gpg` as installed via Homebrew.
# https://stackoverflow.com/a/42265848/96656
export GPG_TTY=$(tty);

# Set some simple and more generous java defaults
export JAVA_OPTS="-Xms512m -Xmx2048m -Dfile.encoding=UTF-8"

export SDKMAN_DIR="$HOME/.sdkman"

export NVM_HOMEBREW=$(brew --prefix nvm)
export NVM_DIR="$HOME/.nvm"

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/sindresorhus/pure/issues/669 re: double venv in prompt
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
