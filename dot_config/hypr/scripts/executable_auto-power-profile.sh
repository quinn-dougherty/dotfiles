#!/usr/bin/env bash
# Auto-switch power-profiles-daemon based on AC state:
#   on AC      -> performance
#   on battery -> power-saver
# Runs in the user session (launched via Hyprland exec-once): sets the profile
# once at startup, then follows UPower's OnBattery property on every plug/unplug.
set -uo pipefail

apply() {
  case "$1" in
    true)  powerprofilesctl set power-saver 2>/dev/null ;;
    false) powerprofilesctl set performance 2>/dev/null ;;
  esac
}

# Initial state at launch
apply "$(busctl --system get-property org.freedesktop.UPower /org/freedesktop/UPower \
           org.freedesktop.UPower OnBattery 2>/dev/null | awk '{print $2}')"

# Follow plug/unplug events (UPower emits PropertiesChanged on OnBattery)
gdbus monitor --system --dest org.freedesktop.UPower --object-path /org/freedesktop/UPower 2>/dev/null |
while read -r line; do
  case "$line" in
    *OnBattery*true*)  apply true  ;;
    *OnBattery*false*) apply false ;;
  esac
done
