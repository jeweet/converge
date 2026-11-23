VERSION   := 0.2.0
DESTDIR   ?=
# The scripts refer to these paths directly; changing them is not supported.
PREFIX    := /usr
SYSCONFDIR := /etc

BINDIR     := $(DESTDIR)$(PREFIX)/bin
LIBEXECDIR := $(DESTDIR)$(PREFIX)/libexec/converge
LIBDIR     := $(DESTDIR)$(PREFIX)/lib/converge
DATADIR    := $(DESTDIR)$(PREFIX)/share/converge
UNITDIR    := $(DESTDIR)$(PREFIX)/lib/systemd/system
USERUNITDIR := $(DESTDIR)$(PREFIX)/lib/systemd/user
UDEVDIR    := $(DESTDIR)$(PREFIX)/lib/udev/rules.d
POLKITDIR  := $(DESTDIR)$(PREFIX)/share/polkit-1/rules.d
APPDIR     := $(DESTDIR)$(PREFIX)/share/applications
SYSCTLDIR  := $(DESTDIR)$(PREFIX)/lib/sysctl.d
MODLOADDIR := $(DESTDIR)$(PREFIX)/lib/modules-load.d
XDGDIR     := $(DESTDIR)$(SYSCONFDIR)/xdg

LIBEXEC_SCRIPTS := switch hyprland-session phosh-session desktop titlebar \
                   battery wallpaper waybar-modem qs rofi-icons touchpad

.PHONY: all install uninstall check dist apk clean

all:
	@echo "Nothing to build. Use 'make install' (DESTDIR=...) or 'make apk'."

install:
	install -Dm755 bin/converge $(BINDIR)/converge
	install -Dm755 bin/converge-settings $(BINDIR)/converge-settings
	for f in $(LIBEXEC_SCRIPTS); do install -Dm755 libexec/$$f $(LIBEXECDIR)/$$f; done
	install -Dm644 lib/common.sh $(LIBDIR)/common.sh
	install -Dm644 lib/converge_displays.py $(LIBDIR)/converge_displays.py
	sed -i 's/@VERSION@/$(VERSION)/' $(LIBDIR)/common.sh
	# Data and packaged default configs
	install -Dm644 data/system.conf $(DATADIR)/system.conf
	install -Dm644 data/pam/session-env.conf $(DATADIR)/pam/session-env.conf
	install -Dm644 data/skel/hyprland.conf $(DATADIR)/skel/hyprland.conf
	install -Dm644 data/config/converge.conf $(DATADIR)/config/converge.conf
	for f in hypr/hyprland.conf hypr/hyprlock.conf hypr/hypridle.conf \
	         waybar/config.jsonc waybar/style.css \
	         swaync/config.json swaync/style.css \
	         rofi/config.rasi rofi/theme.rasi; do \
		install -Dm644 data/config/$$f $(DATADIR)/config/$$f; \
	done
	# System integration
	install -Dm644 etc/converge.conf $(DESTDIR)$(SYSCONFDIR)/converge.conf
	install -Dm644 systemd/system/converge-switch.service $(UNITDIR)/converge-switch.service
	install -Dm644 systemd/system/converge-dock.service $(UNITDIR)/converge-dock.service
	install -Dm644 'systemd/system/converge-action@.service' '$(UNITDIR)/converge-action@.service'
	install -Dm644 systemd/user/converge-hyprland-session.target $(USERUNITDIR)/converge-hyprland-session.target
	install -Dm644 udev/70-converge-uinput.rules $(UDEVDIR)/70-converge-uinput.rules
	install -Dm644 udev/71-converge-touchscreen.rules $(UDEVDIR)/71-converge-touchscreen.rules
	install -Dm644 udev/99-converge.rules $(UDEVDIR)/99-converge.rules
	install -Dm644 polkit/50-converge.rules $(POLKITDIR)/50-converge.rules
	install -Dm644 sysctl/50-converge-quiet-console.conf $(SYSCTLDIR)/50-converge-quiet-console.conf
	install -Dm644 modules-load/converge.conf $(MODLOADDIR)/converge.conf
	install -Dm644 xdg/xdg-desktop-portal/hyprland-portals.conf $(XDGDIR)/xdg-desktop-portal/hyprland-portals.conf
	install -Dm644 xdg/autostart/converge-titlebar-phosh.desktop $(XDGDIR)/autostart/converge-titlebar-phosh.desktop
	install -Dm644 applications/io.github.jeweet.Converge.desktop $(APPDIR)/io.github.jeweet.Converge.desktop

uninstall:
	rm -f $(BINDIR)/converge $(BINDIR)/converge-settings
	rm -rf $(LIBEXECDIR) $(LIBDIR) $(DATADIR)
	rm -f $(UNITDIR)/converge-switch.service $(UNITDIR)/converge-dock.service '$(UNITDIR)/converge-action@.service'
	rm -f $(USERUNITDIR)/converge-hyprland-session.target
	rm -f $(UDEVDIR)/70-converge-uinput.rules $(UDEVDIR)/71-converge-touchscreen.rules $(UDEVDIR)/99-converge.rules
	rm -f $(POLKITDIR)/50-converge.rules $(SYSCTLDIR)/50-converge-quiet-console.conf $(MODLOADDIR)/converge.conf
	rm -f $(XDGDIR)/xdg-desktop-portal/hyprland-portals.conf $(XDGDIR)/autostart/converge-titlebar-phosh.desktop
	rm -f $(APPDIR)/io.github.jeweet.Converge.desktop

# Syntax checks (shellcheck is used when available)
check:
	for f in bin/converge lib/common.sh libexec/switch libexec/hyprland-session \
	         libexec/phosh-session libexec/desktop libexec/titlebar libexec/battery \
	         libexec/wallpaper libexec/waybar-modem libexec/qs; do sh -n $$f || exit 1; done
	for f in bin/converge-settings libexec/rofi-icons libexec/touchpad lib/converge_displays.py; do \
		python3 -c "import ast, sys; ast.parse(open(sys.argv[1]).read())" $$f || exit 1; done
	python3 -c "import json; json.load(open('data/config/swaync/config.json'))"
	if command -v shellcheck >/dev/null; then \
		shellcheck -S error bin/converge lib/common.sh libexec/switch \
		  libexec/hyprland-session libexec/phosh-session libexec/desktop \
		  libexec/titlebar libexec/battery libexec/wallpaper libexec/waybar-modem libexec/qs; \
	fi

# Source tarball for the APKBUILD
dist:
	git archive --format=tar.gz --prefix=converge-$(VERSION)/ \
		-o packaging/alpine/converge-$(VERSION).tar.gz HEAD

# Build the Alpine package (needs alpine-sdk and an abuild key, see README)
apk: dist
	cd packaging/alpine && abuild checksum && abuild -r

clean:
	rm -f packaging/alpine/converge-*.tar.gz
	rm -rf packaging/alpine/src packaging/alpine/pkg
