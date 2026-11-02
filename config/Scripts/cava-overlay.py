#!/usr/bin/env python3
import os
import sys
import signal
import tempfile
import threading
import subprocess

import gi
gi.require_version('Gtk', '3.0')
gi.require_version('GtkLayerShell', '0.1')
from gi.repository import Gtk, GtkLayerShell, Gdk, GLib
import cairo

NUM_BARS = 72
MAX_HEIGHT = 140

cava_conf = f"""
[general]
bars = {NUM_BARS}
framerate = 60

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = binary
bit_format = 8bit

[smoothing]
integral = 77
monstercat = 1
gravity = 100
"""

conf_file = tempfile.NamedTemporaryFile('w', delete=False)
conf_file.write(cava_conf)
conf_file.close()

cava_proc = subprocess.Popen(
    ['cava', '-p', conf_file.name],
    stdin=subprocess.DEVNULL,
    stdout=subprocess.PIPE,
    stderr=subprocess.DEVNULL,
    bufsize=NUM_BARS * 4
)

bars = [0] * NUM_BARS
running = True

def cleanup(*args):
    global running
    running = False
    try:
        cava_proc.terminate()
        cava_proc.wait(timeout=0.3)
    except Exception:
        pass
    try:
        os.remove(conf_file.name)
    except Exception:
        pass
    Gtk.main_quit()
    sys.exit(0)

signal.signal(signal.SIGINT, cleanup)
signal.signal(signal.SIGTERM, cleanup)

def read_cava():
    global bars
    while running:
        data = cava_proc.stdout.read(NUM_BARS)
        if not data:
            break
        bars = list(data)
        GLib.idle_add(win.queue_draw)

threading.Thread(target=read_cava, daemon=True).start()

win = Gtk.Window()
GtkLayerShell.init_for_window(win)
GtkLayerShell.set_namespace(win, 'cava-hud')
GtkLayerShell.set_layer(win, GtkLayerShell.Layer.TOP)
GtkLayerShell.set_keyboard_mode(win, GtkLayerShell.KeyboardMode.NONE)
GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.BOTTOM, True)
GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.LEFT, True)
GtkLayerShell.set_anchor(win, GtkLayerShell.Edge.RIGHT, True)

screen = win.get_screen()
visual = screen.get_rgba_visual()
if visual:
    win.set_visual(visual)

win.set_app_paintable(True)
win.set_events(0)  # Ignore all pointer events at GTK level
win.set_size_request(1600, MAX_HEIGHT)

def apply_passthrough(widget):
    # Set empty input region on widget and GdkWindow -> 100% click/scroll passthrough
    empty_region = cairo.Region()
    widget.input_shape_combine_region(empty_region)
    gw = widget.get_window()
    if gw:
        gw.input_shape_combine_region(empty_region, 0, 0)

win.connect('realize', apply_passthrough)
win.connect('map-event', lambda w, e: (apply_passthrough(w), False)[1])

def on_draw(widget, cr):
    apply_passthrough(widget)

    cr.set_operator(cairo.OPERATOR_CLEAR)
    cr.paint()
    cr.set_operator(cairo.OPERATOR_OVER)

    w = widget.get_allocated_width()
    h = widget.get_allocated_height()

    slot_w = w / NUM_BARS
    gap = 3.5
    bar_w = max(2.0, slot_w - gap)
    radius = min(3.5, bar_w / 2.0)

    for i in range(NUM_BARS):
        val = bars[i] / 255.0
        bar_h = val * (h - 2.0)
        if bar_h < 1.0:
            continue

        x = i * slot_w + gap / 2.0
        y = h - bar_h

        # Rounded top, flat bottom flush against screen bezel
        cr.new_sub_path()
        cr.arc(x + radius, y + radius, radius, 3.14159, 3.14159 * 1.5)
        cr.arc(x + bar_w - radius, y + radius, radius, 3.14159 * 1.5, 0.0)
        cr.line_to(x + bar_w, h)
        cr.line_to(x, h)
        cr.close_path()

        # Catppuccin Mocha Lavender Gradient:
        # Sapphire (#74c7ec) -> Lavender/Blue (#b4befe) -> Lavender (#cba6f7) -> Mauve/Pink tip (#f5c2e7)
        pat = cairo.LinearGradient(x, h, x, y)
        pat.add_color_stop_rgba(0.0, 0.455, 0.780, 0.925, 0.70)  # Sapphire root at bezel
        pat.add_color_stop_rgba(0.35, 0.706, 0.745, 0.996, 0.85) # Lavender-Blue
        pat.add_color_stop_rgba(0.75, 0.796, 0.651, 0.969, 0.92) # Core Lavender
        pat.add_color_stop_rgba(1.0, 0.961, 0.761, 0.906, 0.98)  # Pink/Mauve crest highlight

        cr.set_source(pat)
        cr.fill()

    return False

win.connect('draw', on_draw)
win.show_all()
apply_passthrough(win)

try:
    Gtk.main()
except Exception:
    cleanup()
