# Changelog

## 0.2.0 - 2026-11-23

- Keyboard layouts and XKB options follow GNOME; Super+Space switches
  layouts when there are several
- The GNOME accent color is used for window borders, the bar, notifications
  and the lock screen
- Trusted displays: switch to desktop mode without asking
- Display profiles: scale and resolution per display (recognized by EDID)
- Volume and microphone keys (wpctl), brightness keys for the external
  display (ddcutil), media keys (playerctl)
- Converge app: new phone-friendly layout with a page per display and for
  the installation check (`converge doctor --plain`); "Back to phone" when
  opened in desktop mode
- `converge doctor` checks the udev access rule of /dev/uinput instead of
  your own access (no false warning over SSH)
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
