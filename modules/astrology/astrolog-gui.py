#!/usr/bin/env python3
"""
Astrolog GUI - Simple GTK4 wrapper for astrolog
Generates clean natal chart wheels
"""

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Gdk', '4.0')
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib
import subprocess
import tempfile
import os
from datetime import datetime

class AstrologGUI(Gtk.Application):
    def __init__(self):
        super().__init__(application_id='org.hermetic.astrolog-gui')
        self.chart_path = None

    def do_activate(self):
        win = Gtk.ApplicationWindow(application=self)
        win.set_title("Astrolog")
        win.set_default_size(900, 700)

        # Apply dark theme
        css = Gtk.CssProvider()
        css.load_from_data(b'''
            window {
                background-color: #0d0d14;
            }
            entry, spinbutton {
                background-color: #1a1a2e;
                color: #c9c9d9;
                border: 1px solid #7b68ab;
                border-radius: 6px;
                padding: 8px;
            }
            label {
                color: #c9c9d9;
            }
            button {
                background-color: #7b68ab;
                color: #f5f5ff;
                border-radius: 6px;
                padding: 8px 16px;
            }
            button:hover {
                background-color: #9b59b6;
            }
            .title {
                font-size: 18px;
                font-weight: bold;
                color: #d4a017;
            }
            .section {
                color: #c9a227;
                font-weight: bold;
            }
        ''')
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            css,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        # Main layout
        main_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        main_box.set_margin_top(12)
        main_box.set_margin_bottom(12)
        main_box.set_margin_start(12)
        main_box.set_margin_end(12)

        # Left panel - inputs
        left_panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        left_panel.set_size_request(280, -1)

        # Title
        title = Gtk.Label(label="Natal Chart")
        title.add_css_class("title")
        left_panel.append(title)

        # Date section
        date_label = Gtk.Label(label="Birth Date")
        date_label.add_css_class("section")
        date_label.set_halign(Gtk.Align.START)
        left_panel.append(date_label)

        date_grid = Gtk.Grid()
        date_grid.set_column_spacing(8)
        date_grid.set_row_spacing(4)

        date_grid.attach(Gtk.Label(label="Month"), 0, 0, 1, 1)
        date_grid.attach(Gtk.Label(label="Day"), 1, 0, 1, 1)
        date_grid.attach(Gtk.Label(label="Year"), 2, 0, 1, 1)

        self.month_spin = Gtk.SpinButton.new_with_range(1, 12, 1)
        self.month_spin.set_value(1)
        self.day_spin = Gtk.SpinButton.new_with_range(1, 31, 1)
        self.day_spin.set_value(1)
        self.year_spin = Gtk.SpinButton.new_with_range(1, 2100, 1)
        self.year_spin.set_value(2000)

        date_grid.attach(self.month_spin, 0, 1, 1, 1)
        date_grid.attach(self.day_spin, 1, 1, 1, 1)
        date_grid.attach(self.year_spin, 2, 1, 1, 1)
        left_panel.append(date_grid)

        # Time section
        time_label = Gtk.Label(label="Birth Time")
        time_label.add_css_class("section")
        time_label.set_halign(Gtk.Align.START)
        left_panel.append(time_label)

        time_grid = Gtk.Grid()
        time_grid.set_column_spacing(8)
        time_grid.set_row_spacing(4)

        time_grid.attach(Gtk.Label(label="Hour"), 0, 0, 1, 1)
        time_grid.attach(Gtk.Label(label="Min"), 1, 0, 1, 1)

        self.hour_spin = Gtk.SpinButton.new_with_range(0, 23, 1)
        self.hour_spin.set_value(12)
        self.minute_spin = Gtk.SpinButton.new_with_range(0, 59, 1)
        self.minute_spin.set_value(0)

        time_grid.attach(self.hour_spin, 0, 1, 1, 1)
        time_grid.attach(self.minute_spin, 1, 1, 1, 1)
        left_panel.append(time_grid)

        # Location section
        loc_label = Gtk.Label(label="Location")
        loc_label.add_css_class("section")
        loc_label.set_halign(Gtk.Align.START)
        left_panel.append(loc_label)

        # Preset locations
        preset_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        self.preset_combo = Gtk.ComboBoxText()
        self.preset_combo.append("custom", "Custom")
        self.preset_combo.append("eldorado", "El Dorado, KS")
        self.preset_combo.append("nyc", "New York, NY")
        self.preset_combo.append("london", "London, UK")
        self.preset_combo.append("paris", "Paris, FR")
        self.preset_combo.set_active_id("eldorado")
        self.preset_combo.connect("changed", self.on_preset_changed)
        preset_box.append(self.preset_combo)
        left_panel.append(preset_box)

        loc_grid = Gtk.Grid()
        loc_grid.set_column_spacing(8)
        loc_grid.set_row_spacing(4)

        loc_grid.attach(Gtk.Label(label="Latitude"), 0, 0, 1, 1)
        loc_grid.attach(Gtk.Label(label="Longitude"), 1, 0, 1, 1)

        self.lat_entry = Gtk.Entry()
        self.lat_entry.set_text("37:49N")
        self.lat_entry.set_placeholder_text("37:49N")
        self.lon_entry = Gtk.Entry()
        self.lon_entry.set_text("96:51W")
        self.lon_entry.set_placeholder_text("96:51W")

        loc_grid.attach(self.lat_entry, 0, 1, 1, 1)
        loc_grid.attach(self.lon_entry, 1, 1, 1, 1)
        left_panel.append(loc_grid)

        # Timezone
        tz_grid = Gtk.Grid()
        tz_grid.set_column_spacing(8)
        tz_grid.set_row_spacing(4)
        tz_grid.attach(Gtk.Label(label="Timezone (hrs from GMT)"), 0, 0, 2, 1)
        self.tz_spin = Gtk.SpinButton.new_with_range(-12, 12, 1)
        self.tz_spin.set_value(-6)  # Central Time
        tz_grid.attach(self.tz_spin, 0, 1, 1, 1)
        left_panel.append(tz_grid)

        # Chart options
        opt_label = Gtk.Label(label="Options")
        opt_label.add_css_class("section")
        opt_label.set_halign(Gtk.Align.START)
        left_panel.append(opt_label)

        self.reverse_check = Gtk.CheckButton(label="White background")
        left_panel.append(self.reverse_check)

        self.houses_check = Gtk.CheckButton(label="Show house info")
        self.houses_check.set_active(True)
        left_panel.append(self.houses_check)

        # Generate button
        generate_btn = Gtk.Button(label="Generate Chart")
        generate_btn.connect("clicked", self.generate_chart)
        left_panel.append(generate_btn)

        # Now button
        now_btn = Gtk.Button(label="Set to Now")
        now_btn.connect("clicked", self.set_to_now)
        left_panel.append(now_btn)

        # Spacer
        spacer = Gtk.Box()
        spacer.set_vexpand(True)
        left_panel.append(spacer)

        main_box.append(left_panel)

        # Right panel - chart display
        right_panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        right_panel.set_hexpand(True)
        right_panel.set_vexpand(True)

        # Scrolled window for chart
        scroll = Gtk.ScrolledWindow()
        scroll.set_hexpand(True)
        scroll.set_vexpand(True)

        self.chart_image = Gtk.Picture()
        self.chart_image.set_can_shrink(True)
        self.chart_image.set_content_fit(Gtk.ContentFit.CONTAIN)
        scroll.set_child(self.chart_image)
        right_panel.append(scroll)

        main_box.append(right_panel)

        win.set_child(main_box)
        win.present()

        # Generate initial chart
        self.generate_chart(None)

    def on_preset_changed(self, combo):
        preset = combo.get_active_id()
        locations = {
            "eldorado": ("37:49N", "96:51W", -6),
            "nyc": ("40:43N", "74:00W", -5),
            "london": ("51:30N", "0:07W", 0),
            "paris": ("48:51N", "2:21E", 1),
        }
        if preset in locations:
            lat, lon, tz = locations[preset]
            self.lat_entry.set_text(lat)
            self.lon_entry.set_text(lon)
            self.tz_spin.set_value(tz)

    def set_to_now(self, btn):
        now = datetime.now()
        self.month_spin.set_value(now.month)
        self.day_spin.set_value(now.day)
        self.year_spin.set_value(now.year)
        self.hour_spin.set_value(now.hour)
        self.minute_spin.set_value(now.minute)
        self.generate_chart(None)

    def generate_chart(self, btn):
        month = int(self.month_spin.get_value())
        day = int(self.day_spin.get_value())
        year = int(self.year_spin.get_value())
        hour = int(self.hour_spin.get_value())
        minute = int(self.minute_spin.get_value())

        lat = self.lat_entry.get_text()
        lon = self.lon_entry.get_text()
        tz = int(self.tz_spin.get_value())

        # Format timezone for astrolog
        if tz >= 0:
            tz_str = f"{tz}:00E"
        else:
            tz_str = f"{abs(tz)}:00W"

        time_str = f"{hour}:{minute:02d}"

        # Create temp file for chart
        fd, self.chart_path = tempfile.mkstemp(suffix='.bmp')
        os.close(fd)

        # Build astrolog command
        cmd = [
            "astrolog",
            "-qb", str(month), str(day), str(year), time_str,
            "0",  # No daylight savings adjustment
            tz_str, lon, lat,
            "-X",      # Graphics mode
            "-Xb",     # Bitmap output
            "-Xw", "700", "700",  # Size
            "-Xo", self.chart_path,
        ]

        if self.reverse_check.get_active():
            cmd.append("-Xr")

        if not self.houses_check.get_active():
            cmd.append("-Xt")

        try:
            result = subprocess.run(cmd, capture_output=True, text=True)
            if os.path.exists(self.chart_path) and os.path.getsize(self.chart_path) > 0:
                # Load and display the chart
                pixbuf = GdkPixbuf.Pixbuf.new_from_file(self.chart_path)
                texture = Gdk.Texture.new_for_pixbuf(pixbuf)
                self.chart_image.set_paintable(texture)
            else:
                print(f"Chart generation failed: {result.stderr}")
        except Exception as e:
            print(f"Error generating chart: {e}")

def main():
    app = AstrologGUI()
    app.run(None)

if __name__ == "__main__":
    main()
