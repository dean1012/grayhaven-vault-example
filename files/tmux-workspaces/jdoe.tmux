#!/bin/bash
set -euo pipefail

# Example operator tmux workspace.
# Real workspace files may contain private operator preferences and should live
# only in the private vault repository.

session_name="${GRAYHAVEN_TMUX_SESSION_NAME:-Grayhaven Systems LLC}"

if tmux has-session -t "$session_name" 2>/dev/null; then
   exit 0
fi

tmux new-session -d -s "$session_name" -n "shell" -c "$HOME" "bash -l"
tmux new-window -t "$session_name" -n "work" -c "$HOME" "bash -l"
tmux select-window -t "$session_name:shell"
