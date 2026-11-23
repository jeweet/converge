# shellcheck shell=sh
# shellcheck disable=SC2034
# Shared helpers for Converge scripts. Sourced, not executed.
# Installed as /usr/lib/converge/common.sh

CONVERGE_VERSION="@VERSION@"
CONVERGE_APP_ID="io.github.jeweet.Converge"
CONVERGE_LIBEXEC=/usr/libexec/converge
CONVERGE_DATA=/usr/share/converge
CONVERGE_SYSCONF=/etc/converge.conf
CONVERGE_RUN=/run/converge

# Defaults for the system settings (/etc/converge.conf)
CONVERGE_USER=""
PROMPT_TIMEOUT=60
PERFORMANCE=1
CRASH_SECONDS=20
HYPRLAND_NO_ATOMIC=1

# Defaults for the user settings (~/.config/converge/converge.conf)
PHONE_TOUCHPAD=0
AUDIO_TO_DISPLAY=1
BLOCK_SUSPEND=1
TITLEBAR_DESKTOP="appmenu:close"
TITLEBAR_PHOSH="appmenu:"
BATTERY_WARNINGS="30 20 10 5"
VPN_CONNECTION=""
INTERNAL_DISPLAY=""

converge_user_conf() {
    echo "${XDG_CONFIG_HOME:-$HOME/.config}/converge/converge.conf"
}

# Load the system settings
converge_load_system_conf() {
    # shellcheck disable=SC1090
    [ -r "$CONVERGE_SYSCONF" ] && . "$CONVERGE_SYSCONF"
    return 0
}

# Load the system settings, then the settings of the current user
converge_load_conf() {
    converge_load_system_conf
    _uc=$(converge_user_conf)
    # shellcheck disable=SC1090
    [ -r "$_uc" ] && . "$_uc"
    return 0
}

# The user that gets the automatic login. Order: CONVERGE_USER in
# /etc/converge.conf, the postmarketOS default user (uid 10000), the first
# regular user.
converge_user() {
    if [ -n "$CONVERGE_USER" ]; then
        echo "$CONVERGE_USER"
        return
    fi
    _u=$(getent passwd 10000 2>/dev/null | cut -d: -f1)
    if [ -z "$_u" ]; then
        _u=$(awk -F: '$3 >= 1000 && $3 < 60000 { print $1; exit }' /etc/passwd)
    fi
    echo "$_u"
}

# Path of a config file: the user's override in ~/.config/converge/<rel>
# if it exists, otherwise the packaged default in /usr/share/converge/config.
converge_config() {
    _o="${XDG_CONFIG_HOME:-$HOME/.config}/converge/$1"
    if [ -e "$_o" ]; then echo "$_o"; else echo "$CONVERGE_DATA/config/$1"; fi
}

# Connector name of the built-in display (DSI-1, eDP-1, ...)
converge_internal_display() {
    if [ -n "$INTERNAL_DISPLAY" ]; then
        echo "$INTERNAL_DISPLAY"
        return
    fi
    for _s in /sys/class/drm/card*-DSI-* /sys/class/drm/card*-eDP-*; do
        [ -e "$_s" ] || continue
        _n=${_s##*/}
        echo "${_n#card*-}"
        return
    done
    echo DSI-1
}

# True when an external display is connected
converge_external_connected() {
    for _s in /sys/class/drm/card*-*/status; do
        case "$_s" in *DSI*|*eDP*) continue ;; esac
        [ "$(cat "$_s" 2>/dev/null)" = connected ] && return 0
    done
    return 1
}

# Names of the touchscreens (one per line)
converge_touchscreens() {
    for _e in /sys/class/input/event*; do
        [ -e "$_e" ] || continue
        udevadm info --query=property --path="$_e" 2>/dev/null \
            | grep -qx 'ID_INPUT_TOUCHSCREEN=1' || continue
        cat "$_e/device/name" 2>/dev/null
    done
}

converge_log() {
    # $1 = tag, rest = message
    _t=$1
    shift
    echo "$*" | systemd-cat -t "$_t" 2>/dev/null || echo "$_t: $*" >&2
}
