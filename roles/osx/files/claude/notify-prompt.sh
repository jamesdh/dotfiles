#!/bin/bash
# Notify when Claude Code sends a notification using growlrrr

INPUT=$(cat)
TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"')
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Notification"')

grrr send \
    --title "$TITLE" \
    --reactivate \
    "$MESSAGE"
