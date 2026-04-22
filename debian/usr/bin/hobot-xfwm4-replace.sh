#!/bin/sh
# Run as the desktop user (sunrise). Launched by XFCE session autostart.
set -u

LOG="/tmp/xfwm4.replace.log"

BOOT_ID="$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo unknown)"
SEQ="$$"

log_line() {
  # $* message
  ts="$(date '+%Y-%m-%dT%H:%M:%S%z' 2>/dev/null || date)"
  line="seq=$SEQ boot=$BOOT_ID ts=$ts $*"
  printf '%s\n' "$line" >>"$LOG" 2>/dev/null || true
}

uptime_s() { cut -d' ' -f1 /proc/uptime 2>/dev/null || echo unknown; }

export DISPLAY=:0
export XAUTHORITY=/home/sunrise/.Xauthority

log_line "start DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY"

get_env_from_pid() {
  # $1 pid, $2 key
  pid="$1"
  key="$2"
  tr '\0' '\n' <"/proc/$pid/environ" 2>/dev/null | sed -n "s/^${key}=//p" | head -n1
}

build_env_prefix() {
  # Prefer current process env (autostart usually has these), fallback to xfce4-session.
  dbus="${DBUS_SESSION_BUS_ADDRESS:-}"
  xdg="${XDG_RUNTIME_DIR:-}"
  sm="${SESSION_MANAGER:-}"
  if [ -z "$dbus" ] || [ -z "$xdg" ] || [ -z "$sm" ]; then
    pid="$(pgrep -xo xfce4-session 2>/dev/null || true)"
    if [ -n "$pid" ]; then
      [ -z "$dbus" ] && dbus="$(get_env_from_pid "$pid" DBUS_SESSION_BUS_ADDRESS || true)"
      [ -z "$xdg" ] && xdg="$(get_env_from_pid "$pid" XDG_RUNTIME_DIR || true)"
      [ -z "$sm" ] && sm="$(get_env_from_pid "$pid" SESSION_MANAGER || true)"
    fi
  fi
  prefix=""
  [ -n "$dbus" ] && prefix="$prefix DBUS_SESSION_BUS_ADDRESS=$dbus"
  [ -n "$xdg" ] && prefix="$prefix XDG_RUNTIME_DIR=$xdg"
  [ -n "$sm" ] && prefix="$prefix SESSION_MANAGER=$sm"
  printf '%s' "$prefix"
}

# Run the proven manual fix, but only after the session has stabilized.
# Default to 15s (faster relief after boot); override with HOBOT_XFWM4_LATE_AT_UPTIME_SEC.
LATE_AT="${HOBOT_XFWM4_LATE_AT_UPTIME_SEC:-15}"
(
  while :; do
    up="$(uptime_s)"
    up_i="$(printf '%s' "$up" | cut -d'.' -f1)"
    [ -n "$up_i" ] || up_i=0
    if [ "$up_i" -ge "$LATE_AT" ] 2>/dev/null; then
      break
    fi
    sleep 1
  done

  ENV_PREFIX="$(build_env_prefix)"
  if [ -n "$ENV_PREFIX" ]; then
    log_line "env_prefix_set=1"
  else
    log_line "env_prefix_set=0"
  fi

  log_line "late_trigger uptime=$(uptime_s) target=$LATE_AT"
  pid_before="$(pgrep -xo xfwm4 2>/dev/null || true)"
  log_line "pid_before=${pid_before:-none}"

  # Ensure placement remains centered (avoid top-left fallback after WM restart)
  env $ENV_PREFIX xfconf-query -c xfwm4 -p /general/placement_mode -n -t string -s center >/dev/null 2>&1 || true
  env $ENV_PREFIX xfconf-query -c xfwm4 -p /general/placement_ratio -n -t int -s 20 >/dev/null 2>&1 || true
  # Keep the known flicker-related key consistent
  env $ENV_PREFIX xfconf-query -c xfwm4 -p /general/unredirect_overlays -n -t bool -s false >/dev/null 2>&1 || true

  # Must run as the desktop user session (autostart is already sunrise).
  log_line "run xfwm4 --replace"
  env $ENV_PREFIX /usr/bin/xfwm4 --replace >>"$LOG" 2>&1 &
  rc=$?
  log_line "xfwm4_rc=$rc"
  sleep 1
  pid_after="$(pgrep -xo xfwm4 2>/dev/null || true)"
  log_line "pid_after=${pid_after:-none}"

  # Desktop surface can lag WM compositor changes; best-effort resync
  if command -v xfdesktop >/dev/null 2>&1; then
    ( sleep 2; env $ENV_PREFIX xfdesktop --reload >>"$LOG" 2>&1; log_line "xfdesktop_reload_done" ) &
  fi
) &

exit 0

