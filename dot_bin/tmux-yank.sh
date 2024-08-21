#!/usr/bin/env sh

if command -v pbcopy >/dev/null; then
  exec pbcopy
elif command -v nc >/dev/null && netstat -4 -nl 2>/dev/null | grep -q "[.:]50730"; then
  exec nc -q0 localhost 50730
else
  (>&2 echo "No suitable way to yank! 🙀")
fi
