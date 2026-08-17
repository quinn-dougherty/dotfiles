#!/usr/bin/env bash
# Enable the user services that need to be running before a session is usable.
# The unit files ship with their packages -- all this does is wire them into
# default.target so they come up at login, which is machine state systemd keeps
# outside of $HOME's dotfiles.
#
# talkat  = voice dictation server (SUPER CTRL SPACE in hypr/bindings.conf)
# ydotool = uinput typing daemon; without it talkat can't type into the focused
#           window and silently degrades to pasting via the clipboard.
set -euo pipefail

units=(talkat.service ydotool.service)

# ydotoold opens /dev/uinput, which is root:input 0660. Without the group it
# starts and then fails on every keystroke, so say so loudly rather than
# leaving a green `is-active` that doesn't work.
if ! id -nG | tr ' ' '\n' | grep -qx input; then
  echo "warning: $USER is not in the 'input' group; ydotoold will fail to open /dev/uinput" >&2
  echo "         fix with: sudo usermod -aG input $USER  (then re-login)" >&2
fi

for unit in "${units[@]}"; do
  if ! systemctl --user cat "$unit" >/dev/null 2>&1; then
    echo "skipping $unit: not installed" >&2
    continue
  fi
  systemctl --user enable --now "$unit"
done
