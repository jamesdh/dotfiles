#!/bin/bash

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
	shopt -s "$option" 2> /dev/null;
done;

# Add tab completion for `defaults read|write domain`
domains=$(defaults domains);
complete -W "NSGlobalDomain ${domains//,}" defaults;
unset domains;

# Add `killall` tab completion for common apps
complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter" killall;

# Bash Completion 
[[ -r $HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh ]] && . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
# complete -F _comp_make_recursive make gmake gnumake pmake colormake bmake

# Patterns for bash-completion to ignore
export EXECIGNORE=*/makeinfo:*/make_chlayout_test:$EXECIGNORE

# direnv bash support
eval "$(direnv hook bash)"

# Initialize SDKMAN
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# Autocomplete for kubectl and the 'k' alias I've created for it. 
source <(kubectl completion bash)
complete -F __start_kubectl k

# Google Cloud SDK
source "$HOMEBREW_PREFIX/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc"
source "$HOMEBREW_PREFIX/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc"

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

# This loads nvm
[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && . "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
# This loads nvm bash_completion
[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && . "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"

source /Users/jamesdh/.docker/init-bash.sh || true # Added by Docker Desktop
