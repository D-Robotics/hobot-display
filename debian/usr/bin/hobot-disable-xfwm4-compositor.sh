#!/bin/sh
set -eu

# Disable xfwm4 compositor (and zoom-desktop) to reduce menu flicker on fbdev.
# Edits xfwm4.xml then xfwm4 --replace. No dbus/xfconf-query.

LOG="${TMPDIR:-/tmp}/hobot-disable-xfwm4-compositor.log"

log() {
	# Prefer stable ISO-ish timestamp even if date -Iseconds is unavailable.
	printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z' 2>/dev/null || date)" "$*" >>"$LOG" 2>/dev/null || true
}

get_prop_value() {
	# best-effort parse: returns first matched "value" for given property name
	# $1 = property name, e.g. use_compositing
	grep -o "name=\"$1\"[^>]*value=\"[^\"]*\"" "$CONF_FILE" 2>/dev/null | head -n1 | sed -n 's/.*value="\([^"]*\)".*/\1/p'
}

patch_bool_prop() {
	# $1 = property name without quotes, e.g. use_compositing
	local n="$1"
	if grep -q "name=\"${n}\"" "$CONF_FILE"; then
		sed -i "/name=\"${n}\"/s/value=\"true\"/value=\"false\"/g" "$CONF_FILE"
		sed -i "/name=\"${n}\"/s/value=\"[^\"]*\"/value=\"false\"/g" "$CONF_FILE"
	fi
}

if [ "$(id -u)" -eq 0 ]; then
	USER_NAME="${HOBOT_XFCE_USER:-sunrise}"
	USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6 || true)"
else
	USER_NAME="$(id -un)"
	USER_HOME="${HOME:-$(getent passwd "$USER_NAME" | cut -d: -f6)}"
fi

if [ -z "$USER_HOME" ] || [ ! -d "$USER_HOME" ]; then
	log "no home for $USER_NAME, exit"
	exit 0
fi

: "${DISPLAY:=:0}"
XAUTHORITY="${XAUTHORITY:-$USER_HOME/.Xauthority}"
export DISPLAY XAUTHORITY

# First pass waits for session; second pass (from .desktop) can set delay 0.
sleep "${HOBOT_XFWM4_COMPOSITOR_DELAY:-3}"

CONF_DIR="$USER_HOME/.config/xfce4/xfconf/xfce-perchannel-xml"
CONF_FILE="$CONF_DIR/xfwm4.xml"

mkdir -p "$CONF_DIR"

ensure_xml() {
	if [ ! -f "$CONF_FILE" ]; then
		cat >"$CONF_FILE" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
    <property name="zoom_desktop" type="bool" value="false"/>
  </property>
</channel>
EOF
	fi
}

apply_patches() {
	if grep -q 'name="use_compositing"' "$CONF_FILE"; then
		patch_bool_prop "use_compositing"
	else
		if grep -q '<property name="general"' "$CONF_FILE"; then
			cat >"$CONF_FILE" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
    <property name="zoom_desktop" type="bool" value="false"/>
  </property>
</channel>
EOF
		fi
	fi
	patch_bool_prop "zoom_desktop"
}

ensure_xml
BEFORE_USE_COMPOSITING="$(get_prop_value use_compositing || true)"
apply_patches
AFTER_USE_COMPOSITING="$(get_prop_value use_compositing || true)"

log "after patch use_compositing line: $(grep 'use_compositing' "$CONF_FILE" 2>/dev/null | head -n1 || echo missing)"
log "after patch zoom_desktop line: $(grep 'zoom_desktop' "$CONF_FILE" 2>/dev/null | head -n1 || echo missing)"
log "use_compositing value: ${BEFORE_USE_COMPOSITING:-unknown} -> ${AFTER_USE_COMPOSITING:-unknown}"

if [ "$(id -u)" -eq 0 ]; then
	chown "$USER_NAME":"$USER_NAME" "$CONF_DIR" "$CONF_FILE" 2>/dev/null || true
fi

restart_wm_if_needed() {
	# Only do the heavier restart sequence if we actually turned it off
	# (i.e. XML was true and now is false).
	RESTART_DID=0
	if [ "${BEFORE_USE_COMPOSITING:-}" = "true" ] && [ "${AFTER_USE_COMPOSITING:-}" = "false" ]; then
		log "trigger restart: compositor true->false"
		RESTART_DID=1
	else
		log "skip restart: no true->false transition"
		return 0
	fi

	# Best-effort: in-session xfconf-query makes change stick immediately.
	# Then restart xfwm4 (kill + replace) like the proven manual sequence.
	if [ "$(id -u)" -eq 0 ]; then
		if command -v runuser >/dev/null 2>&1; then
			runuser -u "$USER_NAME" -- env DISPLAY="$DISPLAY" XAUTHORITY="$XAUTHORITY" sh -c '
				xfconf-query -c xfwm4 -p /general/use_compositing -n -t bool -s false 2>/dev/null || true
				killall xfwm4 2>/dev/null || true
				nohup xfwm4 --replace >/tmp/xfwm4.replace.log 2>&1 &
			' >>"$LOG" 2>&1 || log "runuser restart sequence failed"
		else
			su - "$USER_NAME" -c "DISPLAY='$DISPLAY' XAUTHORITY='$XAUTHORITY' sh -c '
				xfconf-query -c xfwm4 -p /general/use_compositing -n -t bool -s false 2>/dev/null || true
				killall xfwm4 2>/dev/null || true
				nohup xfwm4 --replace >/tmp/xfwm4.replace.log 2>&1 &
			'" >>"$LOG" 2>&1 || log "su restart sequence failed"
		fi
	else
		xfconf-query -c xfwm4 -p /general/use_compositing -n -t bool -s false 2>/dev/null || true
		killall xfwm4 2>/dev/null || true
		nohup xfwm4 --replace >/tmp/xfwm4.replace.log 2>&1 &
	fi
}

if [ "$(id -u)" -eq 0 ]; then
	restart_wm_if_needed
else
	restart_wm_if_needed
	if [ "${RESTART_DID:-0}" = "1" ]; then
		log "ran restart sequence as $USER_NAME"
	fi
fi

exit 0
