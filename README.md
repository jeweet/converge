# Converge

**Phosh on the phone, Hyprland when docked.** Convergence for postmarketOS:
plug your phone into a USB-C dock with a monitor, confirm, and you get a full
Hyprland desktop on the big screen. Unplug, and you are back in Phosh on the
lock screen.

Developed and tested on the Fairphone 5 (postmarketOS edge, systemd, Phosh
with greetd + Phrog). Other phones with DisplayPort alt mode should work too;
see [Other devices](#other-devices).

## Features

- **Ask before switching.** On plugging in a display, Phosh shows a
  notification (also on the lock screen): *Desktop mode* or *Stay on phone*.
- **Locked on both sides.** Hyprland starts locked with hyprlock; after
  undocking Phosh starts on its lock screen. Your keyring is unlocked by
  either lock screen.
- **A GNOME-like desktop.** Waybar styled like the GNOME top bar, swaync
  notifications with quick settings (Wi-Fi, mobile data, Bluetooth, VPN), a
  rofi app grid (Super+R), GNOME-style volume indicator for media keys, the
  Phosh wallpaper, dark mode, Adwaita Sans.
- **Follows your GNOME settings.** Keyboard layouts (Settings > Keyboard)
  and the accent color (Settings > Appearance) carry over to Hyprland, the
  bar, notifications and the lock screen.
- **Remembers your displays.** Per display: switch without asking (trusted
  displays), scale and resolution. Set it up in the Converge app.
- **Your phone apps keep working.** Calls, Chatty and other XDG autostart
  services start in desktop mode too.
- **Desktop-mode tweaks.** CPU performance governor, audio to the display,
  no suspend (but locking and screen blanking when idle), close-only
  titlebar buttons, battery warnings.
- **Phone screen as touchpad + keyboard** (optional, Super+T).
- **Safety net.** If Hyprland crashes right after starting, you go back to
  Phosh with a notification.
- **The Converge app** to switch manually, change the settings, set up your
  displays and see the result of the installation check.
- **`converge doctor`** checks the whole setup, for example after system
  updates.

All switching state lives in `/run`: a reboot always brings back the normal
greeter.

## Requirements

- postmarketOS (edge or a recent stable release) with **Phosh**, **systemd**
  and **greetd** (Phrog or another greeter in `/etc/greetd/config.toml`)
- A USB-C dock or cable with DisplayPort alt mode that works on your phone
- The dependencies are pulled in by the package: Hyprland, hyprlock,
  hypridle, Waybar, swaync, rofi, swaybg, GNOME Console, python3 with GTK4,
  libadwaita and evdev

## Installation

### From a release

Download `converge-<version>.apk` from the
[releases](https://github.com/jeweet/converge/releases) and install it:

```sh
sudo apk add --allow-untrusted ./converge-0.1.0-r0.apk
converge setup
```

The release packages are signed with a throwaway CI key, hence
`--allow-untrusted`. Build it yourself (below) if you prefer your own key.

### Build it yourself

On the phone (or any Alpine system; the package is `noarch`):

```sh
sudo apk add alpine-sdk git
sudo addgroup $USER abuild          # log out and in afterwards
abuild-keygen -a -i -n              # once: your signing key

git clone https://github.com/jeweet/converge
cd converge
make apk
sudo apk add ~/.local/share/abuild/packaging/*/converge-*.apk
# (older abuild versions put it in ~/packages/packaging/<arch>/ instead)
converge setup
```

`make apk` packages the last commit (`git archive HEAD`), so commit your
changes before building.

### After installing: `converge setup`

Run `converge setup` once as your normal user (it uses `sudo` for the system
part). It:

- sets `CONVERGE_USER` in `/etc/converge.conf`
- adds keyring unlocking to `/etc/pam.d/hyprlock` and `/etc/pam.d/phosh`,
  and registers the automatic login of greetd as a Wayland session
  (`/etc/pam.d/greetd`)
- enables `converge-switch.service` and reloads the udev rules
- creates `~/.config/converge/converge.conf` and a small
  `~/.config/hypr/hyprland.conf` that loads the Converge desktop
- moves files of an old manual install to a backup

Running it again is safe. Run `converge doctor` any time to check
everything; the Converge app shows a banner when it finds a problem.

### Updating

Install the new package with `apk add` as above. Your settings and your own
Hyprland changes are kept: the packaged configs live in `/usr/share/converge`
and are loaded by your files, not copied into them.

## Usage

1. Plug in the dock. Phosh asks *Switch to desktop mode?*
2. Choose **Desktop mode**. Phosh closes, Hyprland starts on the external
   display. Unlock with your PIN.
3. Unplug, or press **Super+Shift+E**, to go back to Phosh (locked).

On a trusted display (see [Displays](#displays)) there is no question:
the phone switches right away, and Hyprland still starts locked.

If you answer *Stay on phone* or let the question time out, you stay in
Phosh; switch later with the Converge app. When the phone is already docked
at boot, you log in to Phosh as usual and switch with the Converge app.

### Key bindings

| Keys | Action |
| --- | --- |
| Super+Enter | Terminal (GNOME Console) |
| Super+R / Super+D | App launcher (toggle) |
| Super+Q | Close window |
| Super+F | Fullscreen |
| Super+V | Toggle floating |
| Super+L | Lock |
| Super+N | Notification center + quick settings |
| Super+T | Phone screen as touchpad + keyboard |
| Super+1..4 | Switch workspace |
| Super+Shift+1..4 | Move window to workspace |
| Super+arrows | Move focus |
| Super+Shift+arrows | Move window |
| Super+drag | Move window (left button) / resize (right button) |
| Super+Space | Next keyboard layout (with several GNOME layouts) |
| Volume/mute keys | Volume with an on-screen indicator |
| Brightness keys | Brightness of the external display (ddcutil) |
| Play/next/previous | Media players (playerctl) |
| Super+Shift+E | Leave desktop mode |

### Commands

```
converge setup [--yes]          finish the installation
converge doctor [--quiet]       check the installation
converge status                 what is active right now
converge dock                   switch to desktop mode
converge phone                  back to Phosh
converge touchpad on|off|toggle phone screen as touchpad (desktop mode)
converge reset                  back to the normal greeter (sudo)
```

## Configuration

### Your settings: `~/.config/converge/converge.conf`

Most of these are also switches in the Converge app. Changes apply the next
time you dock.

| Setting | Default | Meaning |
| --- | --- | --- |
| `PHONE_TOUCHPAD` | `0` | Keep the phone screen on as touchpad + keyboard |
| `AUDIO_TO_DISPLAY` | `1` | Send audio to the display (DisplayPort/HDMI audio) |
| `BLOCK_SUSPEND` | `1` | No suspend while docked |
| `TITLEBAR_DESKTOP` | `"appmenu:close"` | GTK titlebar buttons in desktop mode |
| `TITLEBAR_PHOSH` | `"appmenu:"` | GTK titlebar buttons in Phosh |
| `BATTERY_WARNINGS` | `"30 20 10 5"` | Notify at these battery percentages (empty = off) |
| `VPN_CONNECTION` | `""` | NetworkManager VPN for the toggle (empty = first WireGuard/VPN) |
| `INTERNAL_DISPLAY` | `""` | Connector of the phone screen (empty = detect DSI/eDP) |

### System settings: `/etc/converge.conf`

| Setting | Default | Meaning |
| --- | --- | --- |
| `CONVERGE_USER` | set by setup | User that is logged in automatically |
| `PROMPT_TIMEOUT` | `60` | Seconds the switch question stays up |
| `PERFORMANCE` | `1` | CPU governor `performance` while docked |
| `CRASH_SECONDS` | `20` | Hyprland exiting sooner than this counts as a crash |
| `HYPRLAND_NO_ATOMIC` | `1` | Legacy KMS in Hyprland (needed on the Fairphone 5) |

### Displays

Open the Converge app with a display connected. Per display you can set:

- **Switch without asking**: desktop mode starts as soon as this display is
  connected (Hyprland still starts locked).
- **Scale**: automatic, 100% to 200%.
- **Resolution**: preferred, highest, or one of the display's modes.

Displays are recognized by their EDID, whatever dock or cable you use. The
settings are stored in `~/.config/converge/displays.conf` and apply the next
time you dock.

### Keyboard and accent color

Converge reads your keyboard layouts and XKB options from GNOME
(`org.gnome.desktop.input-sources`) and the accent color
(`org.gnome.desktop.interface accent-color`) every time you dock. Change
them in GNOME Settings on the phone. With several layouts, Super+Space
switches between them, like in GNOME. Your own `input { ... }` lines in
`~/.config/hypr/hyprland.conf` still win.

### Optional extras

- `swayosd`: the GNOME-style volume indicator (volume keys work without it)
- `playerctl`: play/pause/next keys
- `ddcutil`: brightness keys for the external display, if the monitor and
  the dock support DDC/CI

`converge doctor` tells you which of these are missing.

### Hyprland

`~/.config/hypr/hyprland.conf` loads the packaged config. Add your own
settings below the `source` line; they override the defaults:

```
source = /usr/share/converge/config/hypr/hyprland.conf

decoration {
    rounding = 12
}
bind = SUPER, B, exec, firefox
```

Reload with `hyprctl reload config-only`. Monitor changes need a re-dock:
changing outputs while Hyprland runs can turn the display black on some
phones.

### Bar, notifications, launcher, lock screen

Converge starts these with the packaged config from
`/usr/share/converge/config/`, unless you put your own version in
`~/.config/converge/`:

| Component | Your override |
| --- | --- |
| Waybar | `~/.config/converge/waybar/config.jsonc`, `style.css` |
| swaync | `~/.config/converge/swaync/config.json`, `style.css` |
| rofi | `~/.config/converge/rofi/config.rasi` |
| volume indicator | `~/.config/converge/swayosd/style.css` |
| hyprlock | `~/.config/converge/hypr/hyprlock.conf` |
| hypridle | `~/.config/converge/hypr/hypridle.conf` |

The packaged files use `#3584e4` for the accent color; Converge replaces it
with your GNOME accent when it starts them, in your copies too. You can copy
the packaged file and edit it, or build on it so updates still reach you: Waybar supports `"include": ["/usr/share/converge/config/waybar/config.jsonc"]`,
the CSS files `@import url("/usr/share/converge/config/waybar/style.css");`,
and rofi `@import "/usr/share/converge/config/rofi/config.rasi"`.

### Hiding apps in the launcher

Copy the app's `.desktop` file to `~/.local/share/applications/` and add
`NotShowIn=Hyprland;` (hide in desktop mode only) or `NoDisplay=true` (hide
everywhere) below `[Desktop Entry]`. The launcher list is refreshed every
time you dock; to refresh right away:
`rm -f ~/.cache/rofi-drun-desktop.cache`.

## Troubleshooting

```sh
converge doctor                         # check everything
converge status                         # current state and recent switches
journalctl -u converge-switch -b        # switching
journalctl -b -t converge-hyprland      # desktop session, safety net, touchpad
journalctl -b -t converge-phosh         # Phosh start and locking
journalctl -b -t hyprland               # Hyprland itself
```

Stuck? `converge reset` goes back to the normal greeter, and so does a
reboot.

## Known limitations

- **Fairphone 5: no charging in the dock.** With the phone as USB host, the
  mainline charger driver keeps the input limit at 10 mA even with a USB
  Power Delivery contract. Converge warns when the battery gets low
  (`BATTERY_WARNINGS`).
- **Fairphone 5: no DisplayPort audio.** The kernel exposes no DisplayPort
  PCM yet; audio stays on the phone (use Bluetooth).
- **Fairphone 5: USB 2 devices on the dock** (keyboard, mouse) are not
  detected; USB 3 devices (network, hubs) work. Use Bluetooth or the phone
  touchpad.
- At most two displays: the phone screen and one external display.
- Hyprland needs legacy KMS on the Fairphone 5 (`HYPRLAND_NO_ATOMIC=1`).

## Other devices

Converge detects the phone screen (`DSI-*`/`eDP-*`) and the touchscreen by
itself. Things to check on another phone:

- Try `HYPRLAND_NO_ATOMIC=0` in `/etc/converge.conf`; atomic modesetting is
  preferred where it works.
- Set `INTERNAL_DISPLAY` if the phone screen is not detected.
- `converge doctor` and the journal (above) tell you what is going on.

Reports of working (or non-working) devices are very welcome.

## How it works

- A udev rule starts `converge-switch.service` on every display hotplug.
  `converge-switch` asks in Phosh, then restarts greetd with a generated
  config (in `/run/converge`) whose `initial_session` logs you in straight
  into Hyprland (or, after undocking, into a locked Phosh). The greeter of
  your normal greetd config stays the default session.
- A systemd drop-in in `/run` points greetd to that config, so nothing in
  `/etc` changes and a reboot restores the normal greeter.
- `converge-hyprland-session.target` activates `graphical-session.target`
  and `xdg-desktop-autostart.target`, like gnome-session does for Phosh.
- The automatic login is registered as a Wayland session through `pam_env`;
  otherwise logind treats it as a tty session and polkit refuses e.g. Calls.
- A polkit rule lets the user on the device start only the Converge units
  (switch to desktop mode, back to the phone).

### Files

| Path | What |
| --- | --- |
| `/usr/bin/converge`, `converge-settings` | Command and app |
| `/usr/libexec/converge/` | Switch, session and desktop scripts |
| `/usr/share/converge/config/` | Packaged default configs |
| `/etc/converge.conf` | System settings |
| `/usr/lib/systemd/system/converge-*` | Switch, dock and action services |
| `/usr/lib/udev/rules.d/*converge*` | Hotplug, uinput and touchscreen access |
| `/usr/share/polkit-1/rules.d/50-converge.rules` | Starting the Converge units |

## Uninstalling

```sh
converge reset            # if you are in desktop mode
sudo apk del converge
```

`converge setup` added lines to `/etc/pam.d/hyprlock`, `/etc/pam.d/phosh`
and `/etc/pam.d/greetd` (and may have created the last two). They are
harmless without Converge; remove the `pam_gnome_keyring` and
`/usr/share/converge/pam/session-env.conf` lines if you like. Your files in
`~/.config/converge/` and `~/.config/hypr/hyprland.conf` stay.

## Migrating from the manual install

If you installed an earlier version by copying scripts (`converge-switch`
in `/usr/local/bin`, Dutch file names), install the package and run
`converge setup`. It moves the old files to `/var/backups/converge-*` and
`~/.local/share/converge/backup-*`, migrates your settings (old names such as
`TELEFOONPANEEL` become `PHONE_TOUCHPAD`) and replaces your
`~/.config/hypr/hyprland.conf` by the small loader (the old one goes to the
backup; copy your own changes back in).

## License

MIT, see [LICENSE](LICENSE).
