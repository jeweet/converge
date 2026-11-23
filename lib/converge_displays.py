"""Converge: external displays and the displays you told Converge about.

Each display is identified by a hash of its EDID, so the same monitor is
recognized whichever dock or cable you use. Remembered displays live in
~/.config/converge/displays.conf, one per line:

    # id          trusted  scale  mode       name
    1a2b3c4d5e6f  1        1.5    preferred  DELL U2720Q

trusted  1 = switch to desktop mode without asking
scale    Hyprland scale: auto, 1, 1.25, 1.5, 1.75, 2, ...
mode     preferred, highres, or a resolution such as 2560x1440

Also usable from shell scripts:

    python3 /usr/lib/converge/converge_displays.py current [displays.conf]

prints the first connected external display as tab-separated
"connector id trusted scale mode name", or nothing.
"""

import glob
import hashlib
import os
import sys

HEADER = """\
# Converge: remembered displays (the Converge app edits this file)
# id            trusted  scale  mode         name
"""

DEFAULT = {"trusted": "0", "scale": "1", "mode": "preferred"}


def conf_path(home=None):
    if home:
        return os.path.join(home, ".config", "converge", "displays.conf")
    base = os.environ.get("XDG_CONFIG_HOME",
                          os.path.expanduser("~/.config"))
    return os.path.join(base, "converge", "displays.conf")


def _edid_name(edid):
    """Monitor name from the EDID descriptors, or manufacturer + product."""
    for off in (54, 72, 90, 108):
        block = edid[off:off + 18]
        if len(block) == 18 and block[0:3] == b"\0\0\0" and block[3] == 0xFC:
            name = block[5:18].split(b"\n")[0].decode("ascii", "replace").strip()
            if name:
                return name
    if len(edid) >= 12:
        v = (edid[8] << 8) | edid[9]
        mfg = "".join(chr(((v >> s) & 0x1F) + 64) for s in (10, 5, 0))
        product = edid[10] | (edid[11] << 8)
        return f"{mfg} {product:04X}"
    return "Unknown display"


def external_displays():
    """Connected external displays: list of dicts."""
    result = []
    for status in sorted(glob.glob("/sys/class/drm/card*-*/status")):
        d = os.path.dirname(status)
        connector = os.path.basename(d).split("-", 1)[-1]
        if connector.startswith(("DSI", "eDP")):
            continue
        try:
            with open(status) as f:
                if f.read().strip() != "connected":
                    continue
            with open(os.path.join(d, "edid"), "rb") as f:
                edid = f.read()
        except OSError:
            continue
        modes = []
        try:
            with open(os.path.join(d, "modes")) as f:
                for line in f:
                    m = line.strip()
                    if m and m not in modes:
                        modes.append(m)
        except OSError:
            pass
        if edid:
            ident = hashlib.sha1(edid[:128]).hexdigest()[:12]
            name = _edid_name(edid)
        else:
            ident = "noedid-" + connector
            name = connector
        result.append({"connector": connector, "id": ident,
                       "name": name, "modes": modes})
    return result


def load(path=None):
    """Remembered displays: dict id -> dict(trusted, scale, mode, name)."""
    displays = {}
    try:
        with open(path or conf_path()) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                parts = line.split(None, 4)
                if len(parts) < 4:
                    continue
                ident, trusted, scale, mode = parts[:4]
                name = parts[4] if len(parts) > 4 else ""
                displays[ident] = {"trusted": trusted, "scale": scale,
                                   "mode": mode, "name": name}
    except OSError:
        pass
    return displays


def save(displays, path=None):
    path = path or conf_path()
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        f.write(HEADER)
        for ident, d in sorted(displays.items(),
                               key=lambda kv: kv[1].get("name", "")):
            f.write(f"{ident:<14}  {d['trusted']:<7}  {d['scale']:<5}  "
                    f"{d['mode']:<11}  {d.get('name', '')}\n")
    os.replace(tmp, path)


def settings(ident, displays):
    return {**DEFAULT, **displays.get(ident, {})}


def main(argv):
    if len(argv) >= 2 and argv[1] == "current":
        path = argv[2] if len(argv) > 2 else None
        ext = external_displays()
        if not ext:
            return 0
        e = ext[0]
        s = settings(e["id"], load(path))
        print("\t".join([e["connector"], e["id"], s["trusted"], s["scale"],
                         s["mode"], e["name"]]))
        return 0
    if len(argv) >= 2 and argv[1] == "list":
        for e in external_displays():
            print("\t".join([e["connector"], e["id"], e["name"],
                             " ".join(e["modes"])]))
        return 0
    print("usage: converge_displays.py current [displays.conf] | list",
          file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
