export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# export PS1='\[\033[0;33m\]\u\[\033[0m\]@\[\033[0;32m\]\h\[\033[0m\]:\[\033[1;36m\]\w\[\033[0m\]\$ '
# export LSCOLORS='no=00:fi=00:di=01;31:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:'

# Exports HOMEBREW_PREFIX and updates the PATH to the appropriate Homebrew bin location
if [ "$(arch)" = "arm64" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi

export HOMEBREW_CASK_OPTS='--no-quarantine'

#Updated 'make'
export PATH=$HOMEBREW_PREFIX/opt/make/libexec/gnubin:$PATH

# Python path shenanigans
export PATH=$HOMEBREW_PREFIX/opt/python/libexec/bin:$PATH

# curl
export PATH=$HOMEBREW_PREFIX/opt/curl/bin:$PATH

# Needed for Krew (kubernetes)
export PATH=$PATH:$KREW_BIN

# JetBrains Toolbox (CLI tools)
export PATH="/Users/jamesdh/Library/Application Support/JetBrains/Toolbox/scripts:$PATH"

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

export KREW_BIN="${HOME}/.krew/bin"
