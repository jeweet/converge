# Changelog

## 0.2.0 - 2026-11-23

- Keyboard layouts and XKB options follow GNOME; Super+Space switches
  layouts when there are several
- The GNOME accent color is used for window borders, the bar, notifications,
  the lock screen and the volume indicator
- Trusted displays: switch to desktop mode without asking
- Display profiles: scale and resolution per display (recognized by EDID)
- GNOME-style volume indicator (swayosd) for media keys, with fallback to
  wpctl; brightness keys for the external display via ddcutil; media keys
  via playerctl
- Converge app: displays section and the installation check
  (`converge doctor --plain`)
- Find the greetd config greetd really uses (e.g. Phrog's own)

## 0.1.0 - 2026-11-23

First packaged release.

- Switch between Phosh and Hyprland on display hotplug, with a confirmation
  notification in Phosh (also on the lock screen)
- Hyprland starts locked (hyprlock); Phosh starts locked after undocking
- GNOME-style Waybar, swaync with quick settings, rofi app grid, Phosh
  wallpaper, Adwaita Sans
- Desktop mode: performance governor, audio to the display, no suspend,
  titlebar buttons, battery warnings
- Phone screen as touchpad + keyboard
- Safety net when Hyprland crashes on start
- Converge settings app
- `converge setup`, `converge doctor`, `converge status`
- Migration from the earlier manual (Dutch) install
