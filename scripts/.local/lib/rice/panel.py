"""Base class for the rice-* GTK panels.

Layer-shell surface under waybar, dismissed on Escape or focus loss, toggled
by running it again. Subclass RicePanel, implement build(), pass to run().

Widgets live here, not in the panels, so all five look the same. Stock GTK
widgets are overridden by node structure or replaced -- the theme engine
paints them Adwaita blue otherwise.
"""

import json
import os
import re
import signal
import subprocess
import sys
import threading

import gi

# Both, or Gdk can resolve to 4.0 and the import fails.
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")

HAVE_LAYER_SHELL = True
try:
    gi.require_version("GtkLayerShell", "0.1")
    from gi.repository import GtkLayerShell
except (ValueError, ImportError):
    HAVE_LAYER_SHELL = False

from gi.repository import Gdk, GLib, Gtk, Pango  # noqa: E402

# Escapes, not pasted glyphs -- those get stripped in transit.
CHECK = "\uf00c"          # nf-fa-check
COG = "\uf013"            # nf-fa-cog
REFRESH = "\uf021"        # nf-fa-refresh

# Catppuccin Mocha. ACCENT is substituted at runtime by accent_colour().
CSS = """
/* ── SURFACE ── same recipe as a waybar pill ────────────────────────── */
window {
    background-color: rgba(30, 30, 46, 0.86);
    border: 1px solid rgba(49, 50, 68, 0.9);
    border-radius: 14px;
    font-family: "JetBrainsMono Nerd Font Mono", monospace;
    font-size: 12px;
    color: #cdd6f4;
}
.panel { padding: 14px 16px; }

/* ── TEXT ─────────────────────────────────────────────────────────── */
.title    { color: #cdd6f4; font-size: 13px; font-weight: 600; }
.heading  { color: #6c7086; font-size: 10px; letter-spacing: 1px;
            margin: 2px 0 6px 2px; }
.value    { color: #cdd6f4; }
.big      { color: #cdd6f4; font-size: 20px; font-weight: 600; }
.dim      { color: #6c7086; font-size: 11px; }
.icon     { color: ACCENT; font-size: 15px; }
.icon.muted, .icon.off { color: #6c7086; }

/* ── THE SHARED ROW ── add new row kinds to this list ───────────────── */
list, list row, .row {
    background-color: transparent;
    border: none;
    box-shadow: none;
}
list row, .row {
    border-radius: 8px;
    padding: 4px 8px;
    min-height: 26px;
    transition: background-color 140ms ease;
}
list row:hover, .row:hover { background-color: rgba(49, 50, 68, 0.75); }
list row:selected { background-color: transparent; }
list row:selected:hover { background-color: rgba(49, 50, 68, 0.75); }

.rowlabel { color: #bac2de; }
list row:hover .rowlabel, .row:hover .rowlabel { color: #cdd6f4; }
.rowlabel.active { color: #cdd6f4; }
.rowmeta  { color: #6c7086; font-size: 11px; }
.rowicon  { color: #7f849c; font-size: 12px; }
.rowicon.active { color: ACCENT; }
.check    { color: ACCENT; font-size: 11px; }

/* ── SLIDER ── size comes from trough min-height + slider margin;
 * a height on `scale` itself does nothing. */
scale { padding: 8px 0; min-height: 0; }
scale trough {
    background-color: rgba(49, 50, 68, 0.9);
    border: none;
    border-radius: 999px;
    min-height: 4px;
}
scale highlight {
    background-color: ACCENT;
    border: none;
    border-radius: 999px;
    min-height: 4px;
}
scale slider {
    background-color: #cdd6f4;
    background-image: none;
    border: none;
    box-shadow: none;
    border-radius: 999px;
    min-width: 12px;
    min-height: 12px;
    margin: -5px;
    transition: background-color 120ms ease, min-width 120ms ease,
                min-height 120ms ease, margin 120ms ease;
}
scale:hover slider {
    background-color: #ffffff;
    min-width: 16px;
    min-height: 16px;
    margin: -7px;
}
scale:disabled trough    { background-color: rgba(49, 50, 68, 0.5); }
scale:disabled highlight { background-color: #45475a; }
scale:disabled slider    { background-color: #585b70; }

/* ── TOGGLE ── background-image reset matters: Adwaita's gradient sits
 * on top of background-color and would otherwise win. */
switch {
    background-color: rgba(49, 50, 68, 0.9);
    background-image: none;
    border: none;
    box-shadow: none;
    border-radius: 999px;
    min-width: 34px;
    min-height: 18px;
    padding: 0;
    transition: background-color 160ms ease;
}
switch:checked { background-color: ACCENT; }
switch:disabled { background-color: rgba(49, 50, 68, 0.5); }
switch slider {
    background-color: #cdd6f4;
    background-image: none;
    border: none;
    box-shadow: none;
    border-radius: 999px;
    min-width: 14px;
    min-height: 14px;
    margin: 2px;
}
switch:checked slider { background-color: #1e1e2e; }
switch:disabled slider { background-color: #585b70; }
/* Some Adwaita builds draw ON/OFF marks inside the trough. */
switch image, switch label { color: transparent; }

/* ── BUTTONS AND ENTRIES ──────────────────────────────────────────── */
button {
    background: transparent;
    background-image: none;
    border: none;
    box-shadow: none;
    padding: 0;
    color: #cdd6f4;
}
button:hover { background: transparent; }

entry {
    background-color: rgba(17, 17, 27, 0.8);
    background-image: none;
    color: #cdd6f4;
    caret-color: ACCENT;
    border: 1px solid rgba(49, 50, 68, 0.9);
    border-radius: 8px;
    box-shadow: none;
    padding: 4px 8px;
    min-height: 26px;
}
entry:focus { border-color: ACCENT; }
entry selection { background-color: ACCENT; color: #1e1e2e; }

separator {
    background-color: rgba(49, 50, 68, 0.9);
    min-height: 1px;
    margin: 10px 2px;
}

scrolledwindow, scrolledwindow viewport { background-color: transparent; }
scrollbar { background-color: transparent; border: none; }
scrollbar slider {
    background-color: #45475a;
    border: none;
    border-radius: 999px;
    min-width: 4px;
}
scrollbar slider:hover { background-color: #585b70; }

spinner { color: ACCENT; }
"""


def accent_colour():
    """Follow rice-accent when the wallpaper-derived accent is in use."""
    state = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
    try:
        with open(os.path.join(state, "rice", "accent")) as fh:
            value = fh.readline().strip()
        if re.fullmatch(r"[0-9a-fA-F]{6}", value):
            return "#" + value
    except OSError:
        pass
    return "#cba6f7"                              # Catppuccin mauve


def run_cmd(*args):
    """Run a command, returning stdout ('' if the binary is missing)."""
    try:
        return subprocess.run(
            args, capture_output=True, text=True, check=False
        ).stdout
    except FileNotFoundError:
        return ""


def run_async(args, done=None):
    """run_cmd on a thread; `done(stdout)` fires on the main loop.

    Connecting takes seconds and would freeze the panel mid-click.
    """
    def worker():
        out = run_cmd(*args)
        if done is not None:
            GLib.idle_add(done, out)

    threading.Thread(target=worker, daemon=True).start()


def notify(app, summary, body=""):
    try:
        subprocess.Popen(
            ["notify-send", "-a", app, summary, body],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
    except FileNotFoundError:
        pass


def read_file(path, default=""):
    try:
        with open(path) as fh:
            return fh.read().strip()
    except OSError:
        return default


def focused_monitor():
    """The GdkMonitor for Hyprland's focused output, or None.

    Wayland gives no global pointer position, so the focused output comes
    from hyprctl and is matched to a GdkMonitor by top-left corner.
    """
    try:
        monitors = json.loads(run_cmd("hyprctl", "-j", "monitors") or "[]")
    except (json.JSONDecodeError, TypeError):
        return None

    target = next((m for m in monitors if m.get("focused")), None)
    if target is None:
        return None

    display = Gdk.Display.get_default()
    if display is None:
        return None

    for i in range(display.get_n_monitors()):
        monitor = display.get_monitor(i)
        geometry = monitor.get_geometry()
        if geometry.x == target.get("x") and geometry.y == target.get("y"):
            return monitor
    return None


class RicePanel(Gtk.Window):
    NAME = "rice-panel"
    WIDTH = 340

    def __init__(self):
        super().__init__()
        self.set_size_request(self.WIDTH, -1)

        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        # One namespace for all panels -> one layerrule.
        GtkLayerShell.set_namespace(self, "rice-panel")
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        # Measured after waybar's exclusive zone, i.e. gap below the bar.
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, 6)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.RIGHT, 10)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.ON_DEMAND)

        monitor = focused_monitor()
        if monitor is not None:
            GtkLayerShell.set_monitor(self, monitor)

        self._box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self._box.get_style_context().add_class("panel")
        self.add(self._box)
        self.build(self._box)

        self.connect("key-press-event", self._on_key)
        self.connect("focus-out-event", lambda *_: self.dismiss())

    # ---- to implement -------------------------------------------------
    def build(self, box):
        raise NotImplementedError

    def refresh(self):
        """Rebuild the contents in place, e.g. after a rescan or a toggle."""
        for child in self._box.get_children():
            self._box.remove(child)
            child.destroy()
        self.build(self._box)
        self._box.show_all()

    # ---- shared widgets -----------------------------------------------
    def header(self, box, glyph, title, active=None, on_toggle=None):
        """Icon + title, with an optional master toggle on the right."""
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        row.set_margin_bottom(8)

        icon = Gtk.Label(label=glyph)
        ctx = icon.get_style_context()
        ctx.add_class("icon")
        if active is False:
            ctx.add_class("off")

        label = Gtk.Label(label=title, xalign=0)
        label.get_style_context().add_class("title")
        label.set_hexpand(True)

        row.pack_start(icon, False, False, 2)
        row.pack_start(label, True, True, 0)

        switch = None
        if on_toggle is not None:
            switch = Gtk.Switch()
            switch.set_active(bool(active))
            switch.set_valign(Gtk.Align.CENTER)
            switch.connect("notify::active",
                           lambda s, _p: on_toggle(s.get_active()))
            row.pack_start(switch, False, False, 0)

        box.pack_start(row, False, False, 0)
        return switch

    @staticmethod
    def heading(box, text):
        label = Gtk.Label(label=text, xalign=0)
        label.get_style_context().add_class("heading")
        box.pack_start(label, False, False, 0)
        return label

    @staticmethod
    def separator(box):
        box.pack_start(Gtk.Separator(), False, False, 0)

    @staticmethod
    def info_row(box, left, right, dim=False):
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        row.get_style_context().add_class("row")
        a = Gtk.Label(label=left, xalign=0)
        b = Gtk.Label(label=right, xalign=1)
        a.get_style_context().add_class("dim" if dim else "rowlabel")
        b.get_style_context().add_class("dim" if dim else "value")
        b.set_hexpand(True)
        row.pack_start(a, False, False, 0)
        row.pack_start(b, True, True, 0)
        box.pack_start(row, False, False, 0)
        return b

    def slider_row(self, box, glyph, value, on_change, button_cb=None):
        """Icon (optionally a button) + scale + percentage label."""
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)

        icon = Gtk.Label(label=glyph)
        icon.get_style_context().add_class("icon")
        icon.set_width_chars(2)

        if button_cb:
            button = Gtk.Button()
            button.add(icon)
            button.set_valign(Gtk.Align.CENTER)
            row.pack_start(button, False, False, 2)
        else:
            button = None
            row.pack_start(icon, False, False, 2)

        scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 1)
        scale.set_draw_value(False)
        scale.set_value(value)
        scale.set_hexpand(True)

        # Fixed width or the row twitches at 10% / 100%.
        label = Gtk.Label(label=f"{int(value)}%", xalign=1)
        label.get_style_context().add_class("value")
        label.set_width_chars(4)

        scale.connect("value-changed", lambda s: on_change(int(s.get_value()), label))
        if button_cb:
            button.connect("clicked", button_cb, icon, scale)

        row.pack_start(scale, True, True, 0)
        row.pack_start(label, False, False, 0)
        box.pack_start(row, False, False, 0)
        return icon, scale, label

    def select_list(self, box, entries, on_select, max_visible=0):
        """A pick-one list drawn as checkmark rows.

        entries: (key, label, active) or (key, label, active, glyph, meta).

        max_visible caps the height and scrolls beyond it.
        """
        listbox = Gtk.ListBox()
        listbox.set_selection_mode(Gtk.SelectionMode.NONE)
        rows = []

        for entry in entries:
            key, text, active = entry[0], entry[1], entry[2]
            glyph = entry[3] if len(entry) > 3 else ""
            meta = entry[4] if len(entry) > 4 else ""

            row = Gtk.ListBoxRow()
            row._key = key

            line = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)

            check = Gtk.Label(label=CHECK if active else "")
            check.get_style_context().add_class("check")
            check.set_width_chars(1)
            line.pack_start(check, False, False, 0)

            if glyph:
                gl = Gtk.Label(label=glyph)
                ctx = gl.get_style_context()
                ctx.add_class("rowicon")
                if active:
                    ctx.add_class("active")
                gl.set_width_chars(2)
                line.pack_start(gl, False, False, 0)

            label = Gtk.Label(label=text, xalign=0)
            ctx = label.get_style_context()
            ctx.add_class("rowlabel")
            if active:
                ctx.add_class("active")
            # One long entry must not set the width of the whole panel.
            label.set_ellipsize(Pango.EllipsizeMode.END)
            label.set_max_width_chars(24)
            line.pack_start(label, True, True, 0)

            if meta:
                m = Gtk.Label(label=meta, xalign=1)
                m.get_style_context().add_class("rowmeta")
                line.pack_start(m, False, False, 0)

            row.add(line)
            listbox.add(row)
            rows.append((row, check, label))

        def activated(_listbox, clicked):
            for row, check, label in rows:
                is_active = row is clicked
                check.set_text(CHECK if is_active else "")
                ctx = label.get_style_context()
                (ctx.add_class if is_active else ctx.remove_class)("active")
            on_select(clicked._key)

        listbox.connect("row-activated", activated)

        if max_visible and len(rows) > max_visible:
            scroller = Gtk.ScrolledWindow()
            scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
            # 26px row + 4px gap, matching the CSS.
            height = max_visible * 30
            # All three needed, or it either never grows or never scrolls.
            scroller.set_propagate_natural_height(True)
            scroller.set_min_content_height(height)
            scroller.set_max_content_height(height)
            scroller.add(listbox)
            box.pack_start(scroller, False, False, 0)
        else:
            box.pack_start(listbox, False, False, 0)
        return listbox

    def action_row(self, box, glyph, text, callback):
        """Full-width clickable row: Rescan, Settings, Turn off."""
        button = Gtk.Button()
        button.get_style_context().add_class("row")

        line = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        icon = Gtk.Label(label=glyph)
        icon.get_style_context().add_class("rowicon")
        icon.set_width_chars(1)
        label = Gtk.Label(label=text, xalign=0)
        label.get_style_context().add_class("rowlabel")
        line.pack_start(icon, False, False, 0)
        line.pack_start(label, True, True, 0)
        button.add(line)

        button.connect("clicked", lambda _b: callback())
        box.pack_start(button, False, False, 0)
        return button

    def entry_row(self, box, placeholder, on_submit, password=False):
        """Inline text field (the Wi-Fi password prompt)."""
        entry = Gtk.Entry()
        entry.set_placeholder_text(placeholder)
        entry.set_visibility(not password)
        entry.set_activates_default(False)
        entry.connect("activate", lambda e: on_submit(e.get_text()))
        box.pack_start(entry, False, False, 2)
        entry.grab_focus()
        return entry

    def spinner_row(self, box, text):
        """Shown while something slow is in flight, in place of the list."""
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        row.get_style_context().add_class("row")
        spinner = Gtk.Spinner()
        spinner.start()
        label = Gtk.Label(label=text, xalign=0)
        label.get_style_context().add_class("dim")
        row.pack_start(spinner, False, False, 2)
        row.pack_start(label, True, True, 0)
        box.pack_start(row, False, False, 0)
        return row

    def settings_button(self, box, text, command):
        """An action row that launches an external settings app."""
        return self.action_row(box, COG, text, lambda: self.launch(command))

    def launch(self, command):
        # gnome-control-center exits unless XDG_CURRENT_DESKTOP is GNOME.
        env = dict(os.environ)
        if command and "gnome-control-center" in command[0]:
            env["XDG_CURRENT_DESKTOP"] = "GNOME"
        try:
            subprocess.Popen(
                command, start_new_session=True, env=env,
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            )
        except FileNotFoundError:
            notify(self.NAME, f"{command[0]} is not installed")
        self.dismiss()

    # ---- lifecycle ----------------------------------------------------
    def _on_key(self, _widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.dismiss()
            return True
        return False

    def dismiss(self, *_):
        Gtk.main_quit()


def toggle_guard(name):
    """Running again while open closes it, so a bar click toggles."""
    lock = f"/run/user/{os.getuid()}/{name}.pid"
    if os.path.exists(lock):
        try:
            with open(lock) as fh:
                os.kill(int(fh.read().strip()), signal.SIGTERM)
            os.unlink(lock)
            sys.exit(0)
        except (ValueError, ProcessLookupError, PermissionError, OSError):
            pass
    with open(lock, "w") as fh:
        fh.write(str(os.getpid()))
    return lock


def run(panel_cls, fallback=None):
    if not HAVE_LAYER_SHELL:
        if fallback:
            os.execvp(fallback, [fallback])
        sys.exit(f"{panel_cls.NAME}: gir1.2-gtklayershell-0.1 is required")

    lock = toggle_guard(panel_cls.NAME)

    provider = Gtk.CssProvider()
    provider.load_from_data(CSS.replace("ACCENT", accent_colour()).encode())
    # Above PRIORITY_USER, or ~/.config/gtk-3.0/gtk.css wins the shared rules.
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(), provider,
        Gtk.STYLE_PROVIDER_PRIORITY_USER + 1,
    )

    panel = panel_cls()
    panel.show_all()
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGTERM, Gtk.main_quit)
    try:
        Gtk.main()
    finally:
        try:
            os.unlink(lock)
        except OSError:
            pass
