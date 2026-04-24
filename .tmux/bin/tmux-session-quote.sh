#!/bin/sh

set -eu

session_target="${1:-}"
quotes_file="${HOME}/.cache/tmux-quotes.txt"
max_len=72

if [ -z "$session_target" ]; then
    session_target="$(tmux display-message -p '#{session_id}')"
fi

if ! tmux has-session -t "$session_target" 2>/dev/null; then
    exit 0
fi

existing_quote="$(tmux show-options -qv -t "$session_target" @quote 2>/dev/null || true)"
if [ -n "$existing_quote" ]; then
    exit 0
fi

if [ ! -s "$quotes_file" ]; then
    tmux set-option -t "$session_target" @quote "Quote file missing."
    exit 0
fi

count="$(awk 'END { print NR }' "$quotes_file")"
if [ "${count:-0}" -le 0 ]; then
    tmux set-option -t "$session_target" @quote "No quotes available."
    exit 0
fi

line="$(jot -r 1 1 "$count")"
quote="$(sed -n "${line}p" "$quotes_file" | tr -d '\r')"

case "$quote" in
    *" | "*) quote="${quote%% | *}" ;;
esac

quote_len="$(printf '%s' "$quote" | wc -c | tr -d ' ')"

if [ "$quote_len" -gt "$max_len" ]; then
    quote="$(printf '%s' "$quote" | cut -c1-$((max_len - 3)))..."
fi

tmux set-option -t "$session_target" @quote "$quote"
