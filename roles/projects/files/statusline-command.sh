#!/bin/bash
# Claude Code statusLine
#
# ~/.zshrc doesn't set a literal PS1 — it loads the "pure" zsh prompt
# framework instead (`autoload -U promptinit; promptinit; prompt pure`,
# from oh-my-zsh). Pure shows the current directory (cyan, per the
# `zstyle :prompt:pure:path color cyan` in ~/.zshrc) and the current git
# branch, with a marker when the working tree is dirty. This script
# reproduces that using the JSON Claude Code passes on stdin, and appends
# a Claude-session meta segment Pure can't show:
#   <dir> · <branch>* · <model> · <effort> · <used>/<window> (<context%>)
# All meta fields are read straight from the statusLine JSON (no transcript
# parsing) and degrade gracefully if a field is absent on older versions.

input=$(cat)
dir=$(jq -r '.workspace.current_dir // .cwd' <<< "$input")
model=$(jq -r '.model.display_name // empty' <<< "$input")
effort=$(jq -r '.effort.level // empty' <<< "$input")
ctx_pct_raw=$(jq -r '.context_window.used_percentage // empty' <<< "$input")
ctx_size=$(jq -r '.context_window.context_window_size // empty' <<< "$input")
ctx_used=$(jq -r '.context_window.total_input_tokens // empty' <<< "$input")

# Abbreviate $HOME to ~, like pure does.
display_dir=${dir/#$HOME/\~}

CYAN=$'\033[36m'
GRAY=$'\033[2;37m'
YELLOW=$'\033[33m'
MAGENTA=$'\033[35m'
RESET=$'\033[0m'
# Readable on a dark background. Plain 37 is light gray; 2;37 and especially a
# bare 2m dim the foreground until it's near-invisible, so neither is used for
# text that has to be legible at a glance.
LIGHT_GRAY=$'\033[37m'
BLUE=$'\033[94m'

# 104847 -> 105k, 200000 -> 200k, 1000000 -> 1M, 1500000 -> 1.5M
fmt_tokens() {
  if [ "$1" -ge 1000000 ]; then
    awk -v n="$1" 'BEGIN { s = sprintf("%.1f", n / 1000000); sub(/\.0$/, "", s); print s "M" }'
  else
    printf '%dk' "$(( ($1 + 500) / 1000 ))"
  fi
}

case "$COLORTERM" in
  truecolor|24bit) truecolor=1 ;;
  *)               truecolor=0 ;;
esac

# Warning bands, as "min_percent:hue" pairs. A band's color applies from its
# percentage up to the next one, so the steps tighten as the window fills. Hue
# is degrees on the green -> yellow -> orange -> red arc: 120 green, 60 yellow,
# 0 red. Interpolating green and red as RGB instead would pass through a muddy
# olive rather than a legible yellow, hence the hue rotation.
PCT_BANDS="0:120 25:90 50:60 75:40 85:27 90:14 95:0"

# Color for a 0-100 percentage. Falls back to the nearest color in the
# xterm-256 cube when the terminal doesn't advertise 24-bit color.
pct_color() {
  awk -v p="$1" -v bands="$PCT_BANDS" -v tc="$truecolor" 'BEGIN {
    n = split(bands, b, " ")
    h = 120
    for (i = 1; i <= n; i++) { split(b[i], kv, ":"); if (p >= kv[1]) h = kv[2] }
    if (h >= 60) { r = 255 * (1 - (h - 60) / 60); g = 255 } else { r = 255; g = 255 * (h / 60) }
    if (tc) printf "\033[38;2;%d;%d;0m", r + 0.5, g + 0.5
    else    printf "\033[38;5;%dm", 16 + 36 * int(r / 255 * 5 + 0.5) + 6 * int(g / 255 * 5 + 0.5)
  }'
}

git_branch=""
git_dirty=""
if git --no-optional-locks -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git_branch=$(git --no-optional-locks -C "$dir" symbolic-ref --short HEAD 2>/dev/null \
    || git --no-optional-locks -C "$dir" rev-parse --short HEAD 2>/dev/null)
  if [ -n "$(git --no-optional-locks -C "$dir" status --porcelain 2>/dev/null)" ]; then
    git_dirty="*"
  fi
fi

sep=" ${LIGHT_GRAY}·${RESET} "

# model · effort · context%
meta=""
[ -n "$model" ] && meta="${MAGENTA}${model}${RESET}"

if [ -n "$effort" ]; then
  [ -n "$meta" ] && meta="${meta}${sep}"
  meta="${meta}${BLUE}${effort}${RESET}"
fi

if [ -n "$ctx_pct_raw" ]; then
  ctx_pct=$(printf '%.0f' "$ctx_pct_raw" 2>/dev/null)
  : "${ctx_pct:=0}"
  pct_color=$(pct_color "$ctx_pct")
  # "105k/1M (10%)" — the tokens and the window capacity stay a plain light
  # gray; only the percentage carries the green-to-red gradient, so the colour
  # reads as a single signal. Falls back to a bare percentage on older versions
  # that don't send the token counts.
  if [ -n "$ctx_used" ] && [ -n "$ctx_size" ]; then
    ctx_text="${LIGHT_GRAY}$(fmt_tokens "$ctx_used")/$(fmt_tokens "$ctx_size")${RESET} ${pct_color}(${ctx_pct}%)${RESET}"
  else
    ctx_text="${pct_color}${ctx_pct}%${RESET}"
  fi
  [ -n "$meta" ] && meta="${meta}${sep}"
  meta="${meta}${ctx_text}"
fi

out="${CYAN}${display_dir}${RESET}"
[ -n "$git_branch" ] && out="${out}${sep}${GRAY}${git_branch}${RESET}${YELLOW}${git_dirty}${RESET}"
[ -n "$meta" ] && out="${out}${sep}${meta}"

printf '%s' "$out"
