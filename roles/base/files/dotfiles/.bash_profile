# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/bash_profile.pre.bash" ]] && . "$HOME/.fig/shell/bash_profile.pre.bash"
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

# Add tab completion for many Bash commands
# if which brew &> /dev/null && [ -f "$(brew --prefix)/share/bash-completion/bash_completion" ]; then
	#source "$(brew --prefix)/share/bash-completion/bash_completion";
if which brew &> /dev/null && [ -f "$(brew --prefix)/etc/bash_completion" ]; then
    source "$(brew --prefix)/etc/bash_completion";
elif [ -f /etc/bash_completion ]; then
	source /etc/bash_completion;
fi;

# Add tab completion for `defaults read|write domain`
domains=$(defaults domains);
complete -W "NSGlobalDomain ${domains//,}" defaults;
unset domains;

# Add `killall` tab completion for common apps
complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter" killall;

# Bash Completion 
[ -f $HOMEBREW_PREFIX/etc/bash_completion ] && . $HOMEBREW_PREFIX/etc/bash_completion

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

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/bash_profile.post.bash" ]] && . "$HOME/.fig/shell/bash_profile.post.bash"