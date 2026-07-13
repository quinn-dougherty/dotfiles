#!/usr/bin/env bash
# Respawn swaybg on monitor hotplug so the wallpaper re-lays-out for the new
# geometry. swaybg snapshots output geometry at launch and does NOT re-render
# when outputs are added/removed or a monitor rule (e.g. transform) is applied.
# Launched via exec-once from autostart.conf.
set -uo pipefail

sock="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

respawn_bg() {
  pkill -x swaybg || true
  setsid uwsm-app -- swaybg -i "$HOME/.config/omarchy/current/background" -m fill >/dev/null 2>&1 &
}

# Stream Hyprland's event socket; react to monitor add/remove events.
socat -U - "UNIX-CONNECT:${sock}" | while read -r line; do
  case "$line" in
    monitoradded*|monitorremoved*)
      sleep 0.5   # let Hyprland finish applying monitor rules (incl. transform)
      respawn_bg
      ;;
  esac
done
