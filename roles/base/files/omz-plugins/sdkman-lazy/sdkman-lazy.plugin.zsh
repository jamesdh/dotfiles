# Lazy-load SDKMAN: expose candidate homes and bins statically, and defer
# the real init until `sdk` is first used or we enter an .sdkmanrc directory
# (mirroring sdkman_auto_env, which only checks $PWD). Loading after omz's
# compinit also means sdkman-init sees compdef and skips its own compinit.

[[ -d "${SDKMAN_DIR:-$HOME/.sdkman}" ]] || return 0

export SDKMAN_CANDIDATES_DIR="$SDKMAN_DIR/candidates"
for __sdkman_candidate in "$SDKMAN_CANDIDATES_DIR"/*/current(N); do
    export "${(U)${__sdkman_candidate:h:t}}_HOME=$__sdkman_candidate"
    path=("$__sdkman_candidate/bin" $path)
done
unset __sdkman_candidate

__sdkman_lazy_load() {
    add-zsh-hook -d chpwd __sdkman_lazy_chpwd
    unfunction sdk __sdkman_lazy_chpwd __sdkman_lazy_load 2>/dev/null
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
}
__sdkman_lazy_chpwd() {
    [[ -f .sdkmanrc ]] && __sdkman_lazy_load
}
sdk() {
    __sdkman_lazy_load
    sdk "$@"
}
autoload -Uz add-zsh-hook
add-zsh-hook chpwd __sdkman_lazy_chpwd
# A shell opened directly inside an .sdkmanrc project still gets its env
[[ -f .sdkmanrc ]] && __sdkman_lazy_load
