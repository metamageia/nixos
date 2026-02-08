#!/usr/bin/env python3
"""
Astrolog GUI - Professional Astrology Software
SolarFire-inspired interface with comprehensive chart analysis tools
"""

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Gdk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Gdk, GdkPixbuf, GLib, Gio, Adw
import subprocess
import tempfile
import os
import json
from datetime import datetime, timedelta
from pathlib import Path

# Astrological constants
PLANETS = [
    ("Sun", "☉", "sun"),
    ("Moon", "☽", "moon"),
    ("Mercury", "☿", "mercury"),
    ("Venus", "♀", "venus"),
    ("Mars", "♂", "mars"),
    ("Jupiter", "♃", "jupiter"),
    ("Saturn", "♄", "saturn"),
    ("Uranus", "♅", "uranus"),
    ("Neptune", "♆", "neptune"),
    ("Pluto", "♇", "pluto"),
    ("North Node", "☊", "node"),
    ("Chiron", "⚷", "chiron"),
]

SIGNS = [
    ("Aries", "♈", 0),
    ("Taurus", "♉", 30),
    ("Gemini", "♊", 60),
    ("Cancer", "♋", 90),
    ("Leo", "♌", 120),
    ("Virgo", "♍", 150),
    ("Libra", "♎", 180),
    ("Scorpio", "♏", 210),
    ("Sagittarius", "♐", 240),
    ("Capricorn", "♑", 270),
    ("Aquarius", "♒", 300),
    ("Pisces", "♓", 330),
]

ASPECTS = [
    ("Conjunction", "☌", 0, 8),
    ("Opposition", "☍", 180, 8),
    ("Trine", "△", 120, 8),
    ("Square", "□", 90, 7),
    ("Sextile", "⚹", 60, 6),
    ("Quincunx", "⚻", 150, 3),
    ("Semisextile", "⚺", 30, 2),
    ("Semisquare", "∠", 45, 2),
    ("Sesquiquadrate", "⚼", 135, 2),
]

HOUSE_SYSTEMS = [
    ("Placidus", "P"),
    ("Koch", "K"),
    ("Whole Sign", "W"),
    ("Equal (Asc)", "E"),
    ("Campanus", "C"),
    ("Regiomontanus", "R"),
    ("Porphyry", "O"),
    ("Morinus", "M"),
    ("Topocentric", "T"),
]

PRESET_LOCATIONS = {
    "El Dorado, KS": ("37:49N", "96:51W", -6, "US/Central"),
    "New York, NY": ("40:43N", "74:00W", -5, "US/Eastern"),
    "Los Angeles, CA": ("34:03N", "118:15W", -8, "US/Pacific"),
    "London, UK": ("51:30N", "0:07W", 0, "Europe/London"),
    "Paris, France": ("48:51N", "2:21E", 1, "Europe/Paris"),
    "Sydney, Australia": ("33:52S", "151:12E", 10, "Australia/Sydney"),
    "Tokyo, Japan": ("35:41N", "139:41E", 9, "Asia/Tokyo"),
}

CHART_TYPES = [
    ("Natal", "natal"),
    ("Transit", "transit"),
    ("Progressed", "progressed"),
    ("Solar Return", "solar_return"),
    ("Lunar Return", "lunar_return"),
    ("Synastry", "synastry"),
    ("Composite", "composite"),
]


class ChartProfile:
    """Stores birth data for a chart"""
    def __init__(self, name="", month=1, day=1, year=2000, hour=12, minute=0,
                 lat="37:49N", lon="96:51W", tz=-6, location="El Dorado, KS"):
        self.name = name
        self.month = month
        self.day = day
        self.year = year
        self.hour = hour
        self.minute = minute
        self.lat = lat
        self.lon = lon
        self.tz = tz
        self.location = location

    def to_dict(self):
        return self.__dict__.copy()

    @classmethod
    def from_dict(cls, data):
        return cls(**data)

    def get_datetime(self):
        return datetime(self.year, self.month, self.day, self.hour, self.minute)


class AstrologGUI(Adw.Application):
    def __init__(self):
        super().__init__(application_id='org.hermetic.astrolog-gui',
                         flags=Gio.ApplicationFlags.FLAGS_NONE)
        self.chart_path = None
        self.profiles_dir = Path.home() / ".local" / "share" / "astrolog-gui" / "profiles"
        self.profiles_dir.mkdir(parents=True, exist_ok=True)
        self.current_profile = ChartProfile()
        self.secondary_profile = None  # For synastry/composite
        self.house_system = "P"  # Placidus default
        self.chart_type = "natal"
        self.planet_positions = {}
        self.house_cusps = {}

    def do_activate(self):
        self.win = Adw.ApplicationWindow(application=self)
        self.win.set_title("Astrolog")
        self.win.set_default_size(1400, 900)

        # Apply CSS styling
        self.apply_styles()

        # Main layout
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)

        # Header bar
        header = self.create_header_bar()
        main_box.append(header)

        # Content area with paned layout
        content = Gtk.Paned(orientation=Gtk.Orientation.HORIZONTAL)
        content.set_shrink_start_child(False)
        content.set_shrink_end_child(False)

        # Left panel - Controls
        left_scroll = Gtk.ScrolledWindow()
        left_scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        left_panel = self.create_left_panel()
        left_scroll.set_child(left_panel)
        left_scroll.set_size_request(320, -1)
        content.set_start_child(left_scroll)

        # Right side - Chart and Data panels
        right_paned = Gtk.Paned(orientation=Gtk.Orientation.HORIZONTAL)
        right_paned.set_shrink_start_child(False)
        right_paned.set_shrink_end_child(False)

        # Center - Chart display
        center_panel = self.create_center_panel()
        right_paned.set_start_child(center_panel)

        # Right - Data tables
        right_scroll = Gtk.ScrolledWindow()
        right_scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        right_panel = self.create_right_panel()
        right_scroll.set_child(right_panel)
        right_scroll.set_size_request(340, -1)
        right_paned.set_end_child(right_scroll)

        right_paned.set_position(700)
        content.set_end_child(right_paned)
        content.set_position(320)

        main_box.append(content)

        # Status bar
        status_bar = self.create_status_bar()
        main_box.append(status_bar)

        self.win.set_content(main_box)
        self.win.present()

        # Generate initial chart
        self.set_to_now(None)

    def apply_styles(self):
        css = Gtk.CssProvider()
        css.load_from_data(b'''
            window {
                background-color: #0d0d14;
            }
            .sidebar {
                background-color: #0d0d14;
                border-right: 1px solid #2a2a3e;
            }
            .data-panel {
                background-color: #0d0d14;
                border-left: 1px solid #2a2a3e;
            }
            entry, spinbutton {
                background-color: #1a1a2e;
                color: #c9c9d9;
                border: 1px solid #3a3a5e;
                border-radius: 4px;
                padding: 6px 8px;
                min-height: 20px;
            }
            entry:focus, spinbutton:focus {
                border-color: #7b68ab;
                box-shadow: 0 0 0 1px #7b68ab;
            }
            label {
                color: #c9c9d9;
            }
            .section-title {
                font-size: 11px;
                font-weight: bold;
                color: #d4a017;
                letter-spacing: 1px;
                margin-top: 12px;
                margin-bottom: 6px;
            }
            .dim-label {
                color: #6a6a8a;
                font-size: 11px;
            }
            button {
                background: linear-gradient(to bottom, #3a3a5e, #2a2a4e);
                color: #c9c9d9;
                border: 1px solid #4a4a6e;
                border-radius: 4px;
                padding: 6px 12px;
                min-height: 24px;
            }
            button:hover {
                background: linear-gradient(to bottom, #4a4a6e, #3a3a5e);
                border-color: #7b68ab;
            }
            button.suggested-action {
                background: linear-gradient(to bottom, #7b68ab, #5b4890);
                border-color: #9b88cb;
            }
            button.suggested-action:hover {
                background: linear-gradient(to bottom, #8b78bb, #6b58a0);
            }
            .chart-type-btn {
                padding: 8px 16px;
                border-radius: 6px;
            }
            .chart-type-btn:checked {
                background: linear-gradient(to bottom, #7b68ab, #5b4890);
                border-color: #d4a017;
                color: #f5f5ff;
            }
            dropdown {
                background-color: #1a1a2e;
                color: #c9c9d9;
                border: 1px solid #3a3a5e;
                border-radius: 4px;
            }
            dropdown button {
                background: transparent;
                border: none;
                padding: 4px 8px;
            }
            .data-table {
                background-color: #12121c;
                border: 1px solid #2a2a3e;
                border-radius: 6px;
                padding: 8px;
            }
            .table-header {
                color: #d4a017;
                font-weight: bold;
                font-size: 12px;
                padding: 4px 8px;
                border-bottom: 1px solid #3a3a5e;
            }
            .table-row {
                padding: 3px 8px;
                border-bottom: 1px solid #1a1a2e;
            }
            .table-row:hover {
                background-color: #1a1a2e;
            }
            .planet-symbol {
                font-size: 16px;
                min-width: 24px;
            }
            .sign-symbol {
                font-size: 14px;
                color: #c9a227;
            }
            .degree-text {
                font-family: monospace;
                font-size: 11px;
            }
            .aspect-grid {
                background-color: #12121c;
                border: 1px solid #2a2a3e;
                border-radius: 6px;
            }
            .aspect-cell {
                min-width: 28px;
                min-height: 28px;
                font-size: 14px;
            }
            .aspect-conjunction { color: #d4a017; }
            .aspect-opposition { color: #c94040; }
            .aspect-trine { color: #40c940; }
            .aspect-square { color: #c94040; }
            .aspect-sextile { color: #40a0c9; }
            .status-bar {
                background-color: #0a0a10;
                border-top: 1px solid #2a2a3e;
                padding: 4px 12px;
            }
            .status-bar label {
                font-size: 11px;
            }
            .profile-card {
                background-color: #1a1a2e;
                border: 1px solid #3a3a5e;
                border-radius: 6px;
                padding: 8px;
                margin: 4px 0;
            }
            .profile-card:hover {
                border-color: #7b68ab;
            }
            headerbar {
                background: linear-gradient(to bottom, #1a1a2e, #0d0d14);
                border-bottom: 1px solid #2a2a3e;
            }
            .fire-sign { color: #e74c3c; }
            .earth-sign { color: #27ae60; }
            .air-sign { color: #3498db; }
            .water-sign { color: #9b59b6; }
        ''')
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            css,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def create_header_bar(self):
        header = Adw.HeaderBar()

        # App title
        title = Gtk.Label(label="Astrolog")
        title.add_css_class("title")
        header.set_title_widget(title)

        # Left buttons
        menu_btn = Gtk.MenuButton()
        menu_btn.set_icon_name("open-menu-symbolic")
        menu = Gio.Menu()
        menu.append("New Chart", "app.new")
        menu.append("Open Profile...", "app.open")
        menu.append("Save Profile", "app.save")
        menu.append("Export Chart...", "app.export")
        menu.append("About", "app.about")
        menu_btn.set_menu_model(menu)
        header.pack_start(menu_btn)

        # Quick actions
        now_btn = Gtk.Button(label="Now")
        now_btn.set_tooltip_text("Set chart to current time")
        now_btn.connect("clicked", self.set_to_now)
        header.pack_start(now_btn)

        # Right buttons
        animate_btn = Gtk.Button()
        animate_btn.set_icon_name("media-playback-start-symbolic")
        animate_btn.set_tooltip_text("Animate chart")
        header.pack_end(animate_btn)

        settings_btn = Gtk.Button()
        settings_btn.set_icon_name("emblem-system-symbolic")
        settings_btn.set_tooltip_text("Settings")
        header.pack_end(settings_btn)

        return header

    def create_left_panel(self):
        panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        panel.add_css_class("sidebar")
        panel.set_margin_top(12)
        panel.set_margin_bottom(12)
        panel.set_margin_start(12)
        panel.set_margin_end(12)

        # Chart Type Selection
        type_label = Gtk.Label(label="CHART TYPE")
        type_label.add_css_class("section-title")
        type_label.set_halign(Gtk.Align.START)
        panel.append(type_label)

        type_box = Gtk.FlowBox()
        type_box.set_selection_mode(Gtk.SelectionMode.NONE)
        type_box.set_max_children_per_line(3)
        type_box.set_column_spacing(4)
        type_box.set_row_spacing(4)

        self.chart_type_buttons = {}
        for name, type_id in CHART_TYPES[:4]:  # Main types
            btn = Gtk.ToggleButton(label=name)
            btn.add_css_class("chart-type-btn")
            btn.connect("toggled", self.on_chart_type_changed, type_id)
            self.chart_type_buttons[type_id] = btn
            type_box.append(btn)

        self.chart_type_buttons["natal"].set_active(True)
        panel.append(type_box)

        # Birth Data Section
        birth_label = Gtk.Label(label="BIRTH DATA")
        birth_label.add_css_class("section-title")
        birth_label.set_halign(Gtk.Align.START)
        panel.append(birth_label)

        # Name entry
        name_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        name_lbl = Gtk.Label(label="Name")
        name_lbl.add_css_class("dim-label")
        name_lbl.set_halign(Gtk.Align.START)
        name_box.append(name_lbl)
        self.name_entry = Gtk.Entry()
        self.name_entry.set_placeholder_text("Chart name...")
        name_box.append(self.name_entry)
        panel.append(name_box)

        # Date inputs
        date_label = Gtk.Label(label="Date")
        date_label.add_css_class("dim-label")
        date_label.set_halign(Gtk.Align.START)
        panel.append(date_label)

        date_grid = Gtk.Grid()
        date_grid.set_column_spacing(8)
        date_grid.set_row_spacing(4)

        month_lbl = Gtk.Label(label="Month")
        month_lbl.add_css_class("dim-label")
        day_lbl = Gtk.Label(label="Day")
        day_lbl.add_css_class("dim-label")
        year_lbl = Gtk.Label(label="Year")
        year_lbl.add_css_class("dim-label")

        date_grid.attach(month_lbl, 0, 0, 1, 1)
        date_grid.attach(day_lbl, 1, 0, 1, 1)
        date_grid.attach(year_lbl, 2, 0, 1, 1)

        self.month_spin = Gtk.SpinButton.new_with_range(1, 12, 1)
        self.month_spin.set_value(1)
        self.day_spin = Gtk.SpinButton.new_with_range(1, 31, 1)
        self.day_spin.set_value(1)
        self.year_spin = Gtk.SpinButton.new_with_range(1, 2100, 1)
        self.year_spin.set_value(2000)

        date_grid.attach(self.month_spin, 0, 1, 1, 1)
        date_grid.attach(self.day_spin, 1, 1, 1, 1)
        date_grid.attach(self.year_spin, 2, 1, 1, 1)
        panel.append(date_grid)

        # Time inputs
        time_label = Gtk.Label(label="Time")
        time_label.add_css_class("dim-label")
        time_label.set_halign(Gtk.Align.START)
        panel.append(time_label)

        time_grid = Gtk.Grid()
        time_grid.set_column_spacing(8)

        hour_lbl = Gtk.Label(label="Hour")
        hour_lbl.add_css_class("dim-label")
        min_lbl = Gtk.Label(label="Min")
        min_lbl.add_css_class("dim-label")

        time_grid.attach(hour_lbl, 0, 0, 1, 1)
        time_grid.attach(min_lbl, 1, 0, 1, 1)

        self.hour_spin = Gtk.SpinButton.new_with_range(0, 23, 1)
        self.hour_spin.set_value(12)
        self.minute_spin = Gtk.SpinButton.new_with_range(0, 59, 1)
        self.minute_spin.set_value(0)

        time_grid.attach(self.hour_spin, 0, 1, 1, 1)
        time_grid.attach(self.minute_spin, 1, 1, 1, 1)
        panel.append(time_grid)

        # Location Section
        loc_label = Gtk.Label(label="LOCATION")
        loc_label.add_css_class("section-title")
        loc_label.set_halign(Gtk.Align.START)
        panel.append(loc_label)

        # Location preset dropdown
        location_model = Gtk.StringList()
        location_model.append("Custom")
        for loc_name in PRESET_LOCATIONS.keys():
            location_model.append(loc_name)

        self.location_dropdown = Gtk.DropDown(model=location_model)
        self.location_dropdown.set_selected(1)  # Default to El Dorado
        self.location_dropdown.connect("notify::selected", self.on_location_changed)
        panel.append(self.location_dropdown)

        # Lat/Lon inputs
        coord_grid = Gtk.Grid()
        coord_grid.set_column_spacing(8)
        coord_grid.set_row_spacing(4)

        lat_lbl = Gtk.Label(label="Latitude")
        lat_lbl.add_css_class("dim-label")
        lon_lbl = Gtk.Label(label="Longitude")
        lon_lbl.add_css_class("dim-label")

        coord_grid.attach(lat_lbl, 0, 0, 1, 1)
        coord_grid.attach(lon_lbl, 1, 0, 1, 1)

        self.lat_entry = Gtk.Entry()
        self.lat_entry.set_text("37:49N")
        self.lon_entry = Gtk.Entry()
        self.lon_entry.set_text("96:51W")

        coord_grid.attach(self.lat_entry, 0, 1, 1, 1)
        coord_grid.attach(self.lon_entry, 1, 1, 1, 1)
        panel.append(coord_grid)

        # Timezone
        tz_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        tz_lbl = Gtk.Label(label="Timezone (GMT)")
        tz_lbl.add_css_class("dim-label")
        tz_box.append(tz_lbl)
        self.tz_spin = Gtk.SpinButton.new_with_range(-12, 14, 1)
        self.tz_spin.set_value(-6)
        tz_box.append(self.tz_spin)
        panel.append(tz_box)

        # House System Section
        house_label = Gtk.Label(label="HOUSE SYSTEM")
        house_label.add_css_class("section-title")
        house_label.set_halign(Gtk.Align.START)
        panel.append(house_label)

        house_model = Gtk.StringList()
        for name, _ in HOUSE_SYSTEMS:
            house_model.append(name)

        self.house_dropdown = Gtk.DropDown(model=house_model)
        self.house_dropdown.set_selected(0)  # Placidus
        self.house_dropdown.connect("notify::selected", self.on_house_system_changed)
        panel.append(self.house_dropdown)

        # Options Section
        opt_label = Gtk.Label(label="DISPLAY OPTIONS")
        opt_label.add_css_class("section-title")
        opt_label.set_halign(Gtk.Align.START)
        panel.append(opt_label)

        # Chart size scale
        size_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        size_lbl = Gtk.Label(label="Chart Size")
        size_lbl.add_css_class("dim-label")
        size_lbl.set_size_request(80, -1)
        size_box.append(size_lbl)
        self.size_scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 800, 1600, 100)
        self.size_scale.set_value(1200)
        self.size_scale.set_hexpand(True)
        self.size_scale.set_draw_value(False)
        size_box.append(self.size_scale)
        panel.append(size_box)

        # Glyph scale
        glyph_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        glyph_lbl = Gtk.Label(label="Glyph Size")
        glyph_lbl.add_css_class("dim-label")
        glyph_lbl.set_size_request(80, -1)
        glyph_box.append(glyph_lbl)
        self.glyph_scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 100, 400, 50)
        self.glyph_scale.set_value(200)
        self.glyph_scale.set_hexpand(True)
        self.glyph_scale.set_draw_value(False)
        glyph_box.append(self.glyph_scale)
        panel.append(glyph_box)

        # Checkboxes
        self.reverse_check = Gtk.CheckButton(label="Light background")
        panel.append(self.reverse_check)

        self.thick_lines_check = Gtk.CheckButton(label="Thick lines")
        self.thick_lines_check.set_active(True)
        panel.append(self.thick_lines_check)

        self.aspects_check = Gtk.CheckButton(label="Show aspect lines")
        self.aspects_check.set_active(True)
        panel.append(self.aspects_check)

        self.aspect_glyphs_check = Gtk.CheckButton(label="Aspect glyphs on lines")
        self.aspect_glyphs_check.set_active(True)
        panel.append(self.aspect_glyphs_check)

        self.houses_check = Gtk.CheckButton(label="Show house info")
        self.houses_check.set_active(True)
        panel.append(self.houses_check)

        # Action Buttons
        action_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        action_box.set_margin_top(16)

        generate_btn = Gtk.Button(label="Calculate Chart")
        generate_btn.add_css_class("suggested-action")
        generate_btn.connect("clicked", self.generate_chart)
        action_box.append(generate_btn)

        btn_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        btn_row.set_homogeneous(True)

        save_btn = Gtk.Button(label="Save")
        save_btn.connect("clicked", self.save_profile)
        btn_row.append(save_btn)

        load_btn = Gtk.Button(label="Load")
        load_btn.connect("clicked", self.show_load_dialog)
        btn_row.append(load_btn)

        action_box.append(btn_row)
        panel.append(action_box)

        # Saved Profiles Section
        profiles_label = Gtk.Label(label="SAVED CHARTS")
        profiles_label.add_css_class("section-title")
        profiles_label.set_halign(Gtk.Align.START)
        panel.append(profiles_label)

        self.profiles_list = Gtk.ListBox()
        self.profiles_list.set_selection_mode(Gtk.SelectionMode.SINGLE)
        self.profiles_list.connect("row-activated", self.on_profile_selected)
        self.load_profiles_list()
        panel.append(self.profiles_list)

        # Spacer
        spacer = Gtk.Box()
        spacer.set_vexpand(True)
        panel.append(spacer)

        return panel

    def create_center_panel(self):
        panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        panel.set_hexpand(True)
        panel.set_vexpand(True)

        # Chart display area
        scroll = Gtk.ScrolledWindow()
        scroll.set_hexpand(True)
        scroll.set_vexpand(True)

        self.chart_image = Gtk.Picture()
        self.chart_image.set_can_shrink(True)
        self.chart_image.set_content_fit(Gtk.ContentFit.CONTAIN)
        scroll.set_child(self.chart_image)

        panel.append(scroll)

        return panel

    def create_right_panel(self):
        panel = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        panel.add_css_class("data-panel")
        panel.set_margin_top(12)
        panel.set_margin_bottom(12)
        panel.set_margin_start(12)
        panel.set_margin_end(12)

        # Planet Positions Table
        planets_label = Gtk.Label(label="PLANETARY POSITIONS")
        planets_label.add_css_class("section-title")
        planets_label.set_halign(Gtk.Align.START)
        panel.append(planets_label)

        self.planets_table = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.planets_table.add_css_class("data-table")

        # Header
        header_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        header_row.add_css_class("table-header")
        for label, width in [("Planet", 80), ("Sign", 50), ("Degree", 80), ("House", 50)]:
            lbl = Gtk.Label(label=label)
            lbl.set_xalign(0)
            lbl.set_size_request(width, -1)
            header_row.append(lbl)
        self.planets_table.append(header_row)

        self.planet_rows_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.planets_table.append(self.planet_rows_box)
        panel.append(self.planets_table)

        # House Cusps Table
        houses_label = Gtk.Label(label="HOUSE CUSPS")
        houses_label.add_css_class("section-title")
        houses_label.set_halign(Gtk.Align.START)
        panel.append(houses_label)

        self.houses_table = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.houses_table.add_css_class("data-table")

        # Header
        header_row2 = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        header_row2.add_css_class("table-header")
        for label, width in [("House", 60), ("Sign", 50), ("Degree", 100)]:
            lbl = Gtk.Label(label=label)
            lbl.set_xalign(0)
            lbl.set_size_request(width, -1)
            header_row2.append(lbl)
        self.houses_table.append(header_row2)

        self.house_rows_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.houses_table.append(self.house_rows_box)
        panel.append(self.houses_table)

        # Aspect Grid
        aspects_label = Gtk.Label(label="ASPECT GRID")
        aspects_label.add_css_class("section-title")
        aspects_label.set_halign(Gtk.Align.START)
        panel.append(aspects_label)

        self.aspect_grid_widget = Gtk.Grid()
        self.aspect_grid_widget.add_css_class("aspect-grid")
        self.aspect_grid_widget.set_column_homogeneous(True)
        self.aspect_grid_widget.set_row_homogeneous(True)
        panel.append(self.aspect_grid_widget)

        # Chart Info
        info_label = Gtk.Label(label="CHART INFO")
        info_label.add_css_class("section-title")
        info_label.set_halign(Gtk.Align.START)
        panel.append(info_label)

        self.chart_info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        self.chart_info_box.add_css_class("data-table")
        panel.append(self.chart_info_box)

        return panel

    def create_status_bar(self):
        status = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        status.add_css_class("status-bar")

        # Planetary hour
        self.planetary_hour_label = Gtk.Label(label="☉ Planetary Hour: --")
        status.append(self.planetary_hour_label)

        # Current time
        self.current_time_label = Gtk.Label()
        self.current_time_label.set_hexpand(True)
        self.current_time_label.set_halign(Gtk.Align.END)
        status.append(self.current_time_label)

        # Update time every second
        GLib.timeout_add_seconds(1, self.update_status_bar)
        self.update_status_bar()

        return status

    def update_status_bar(self):
        now = datetime.now()
        self.current_time_label.set_label(now.strftime("%A, %B %d, %Y  %I:%M:%S %p"))

        # Update planetary hour
        try:
            result = subprocess.run(["planetary-hours"], capture_output=True, text=True, timeout=5)
            if result.returncode == 0:
                data = json.loads(result.stdout)
                self.planetary_hour_label.set_label(f"{data['symbol']} Hour of {data['planet']}")
        except:
            pass

        return True  # Continue timer

    def on_chart_type_changed(self, button, type_id):
        if button.get_active():
            self.chart_type = type_id
            # Deactivate other buttons
            for tid, btn in self.chart_type_buttons.items():
                if tid != type_id:
                    btn.set_active(False)

    def on_location_changed(self, dropdown, _):
        selected = dropdown.get_selected()
        if selected == 0:  # Custom
            return

        locations = list(PRESET_LOCATIONS.keys())
        if selected > 0 and selected <= len(locations):
            loc_name = locations[selected - 1]
            lat, lon, tz, _ = PRESET_LOCATIONS[loc_name]
            self.lat_entry.set_text(lat)
            self.lon_entry.set_text(lon)
            self.tz_spin.set_value(tz)

    def on_house_system_changed(self, dropdown, _):
        selected = dropdown.get_selected()
        if selected < len(HOUSE_SYSTEMS):
            self.house_system = HOUSE_SYSTEMS[selected][1]

    def set_to_now(self, btn):
        now = datetime.now()
        self.month_spin.set_value(now.month)
        self.day_spin.set_value(now.day)
        self.year_spin.set_value(now.year)
        self.hour_spin.set_value(now.hour)
        self.minute_spin.set_value(now.minute)
        self.name_entry.set_text(f"Chart for {now.strftime('%Y-%m-%d %H:%M')}")
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

        # Get display settings
        chart_size = int(self.size_scale.get_value())
        glyph_size = int(self.glyph_scale.get_value())

        # Build astrolog command for chart image
        cmd = [
            "astrolog",
            "-qb", str(month), str(day), str(year), time_str,
            "0",  # No daylight savings adjustment
            tz_str, lon, lat,
            "-c", self.house_system,  # House system
            "-X",       # Graphics mode
            "-Xb",      # Bitmap output
            "-Xbn",     # X11 bitmap format (better quality)
            "-Xw", str(chart_size), str(chart_size),  # Chart size
            "-Xs", str(glyph_size),   # Scale glyphs/characters
            "-XS", str(glyph_size),   # Scale text
            "-Xv", "1", # Fill style for wheel wedges (subtle shading)
            "-Xo", self.chart_path,
        ]

        # Display options
        if self.reverse_check.get_active():
            cmd.append("-Xr")

        if self.thick_lines_check.get_active():
            cmd.append("-Xx")  # Thicker lines

        if self.aspect_glyphs_check.get_active():
            cmd.append("-XA")  # Draw aspect glyphs on lines

        if self.aspects_check.get_active():
            cmd.extend(["-A", "5"])  # Show major aspects only

        if not self.houses_check.get_active():
            cmd.append("-Xt")

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            if os.path.exists(self.chart_path) and os.path.getsize(self.chart_path) > 0:
                pixbuf = GdkPixbuf.Pixbuf.new_from_file(self.chart_path)
                texture = Gdk.Texture.new_for_pixbuf(pixbuf)
                self.chart_image.set_paintable(texture)
        except Exception as e:
            print(f"Error generating chart: {e}")

        # Get planet positions
        self.get_planet_positions(month, day, year, time_str, tz_str, lon, lat)

        # Update current profile
        self.current_profile = ChartProfile(
            name=self.name_entry.get_text(),
            month=month, day=day, year=year,
            hour=hour, minute=minute,
            lat=lat, lon=lon, tz=tz
        )

    def get_planet_positions(self, month, day, year, time_str, tz_str, lon, lat):
        """Get planet and house positions from astrolog text output"""
        cmd = [
            "astrolog",
            "-qb", str(month), str(day), str(year), time_str,
            "0", tz_str, lon, lat,
            f"-c", self.house_system,
        ]

        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            self.parse_astrolog_output(result.stdout)
        except Exception as e:
            print(f"Error getting positions: {e}")

    def parse_astrolog_output(self, output):
        """Parse astrolog text output and update tables"""
        # Clear existing rows
        while True:
            child = self.planet_rows_box.get_first_child()
            if child:
                self.planet_rows_box.remove(child)
            else:
                break

        while True:
            child = self.house_rows_box.get_first_child()
            if child:
                self.house_rows_box.remove(child)
            else:
                break

        while True:
            child = self.chart_info_box.get_first_child()
            if child:
                self.chart_info_box.remove(child)
            else:
                break

        # Parse output lines
        lines = output.strip().split('\n')
        planet_positions = {}
        house_cusps = {}

        for line in lines:
            line = line.strip()
            if not line:
                continue

            # Parse planet lines (e.g., "Sun    : 15Aqu23")
            for planet_name, symbol, _ in PLANETS:
                if line.startswith(planet_name) and ':' in line:
                    parts = line.split(':')
                    if len(parts) >= 2:
                        pos = parts[1].strip().split()[0] if parts[1].strip() else ""
                        planet_positions[planet_name] = {
                            'symbol': symbol,
                            'position': pos,
                        }
                    break

            # Parse house cusps (e.g., "1st Cusp: 10Lib45")
            for i in range(1, 13):
                suffixes = {1: 'st', 2: 'nd', 3: 'rd'}
                suffix = suffixes.get(i, 'th')
                prefix = f"{i}{suffix} Cusp"
                if line.startswith(prefix) and ':' in line:
                    parts = line.split(':')
                    if len(parts) >= 2:
                        pos = parts[1].strip().split()[0] if parts[1].strip() else ""
                        house_cusps[i] = pos
                    break

        # Update planet table with parsed or placeholder data
        for planet_name, symbol, _ in PLANETS[:10]:  # Main planets
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
            row.add_css_class("table-row")

            # Planet symbol and name
            planet_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
            sym_lbl = Gtk.Label(label=symbol)
            sym_lbl.add_css_class("planet-symbol")
            planet_box.append(sym_lbl)
            name_lbl = Gtk.Label(label=planet_name[:3])
            planet_box.append(name_lbl)
            planet_box.set_size_request(80, -1)
            row.append(planet_box)

            # Get position data
            pos_data = planet_positions.get(planet_name, {})
            pos_str = pos_data.get('position', '--')

            # Parse position to extract sign and degree
            sign_sym = "--"
            degree_str = "--"
            house_str = "--"

            if pos_str and pos_str != '--':
                # Try to parse position like "15Aqu23"
                for sign_name, sign_symbol, _ in SIGNS:
                    abbrev = sign_name[:3]
                    if abbrev in pos_str:
                        sign_sym = sign_symbol
                        parts = pos_str.split(abbrev)
                        if len(parts) >= 2:
                            degree_str = f"{parts[0]}°{parts[1]}'"
                        break

            sign_lbl = Gtk.Label(label=sign_sym)
            sign_lbl.add_css_class("sign-symbol")
            sign_lbl.set_size_request(50, -1)
            row.append(sign_lbl)

            deg_lbl = Gtk.Label(label=degree_str)
            deg_lbl.add_css_class("degree-text")
            deg_lbl.set_size_request(80, -1)
            deg_lbl.set_xalign(0)
            row.append(deg_lbl)

            house_lbl = Gtk.Label(label=house_str)
            house_lbl.set_size_request(50, -1)
            row.append(house_lbl)

            self.planet_rows_box.append(row)

        # Update house cusps table
        for i in range(1, 13):
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
            row.add_css_class("table-row")

            house_num = Gtk.Label(label=f"{i}")
            house_num.set_size_request(60, -1)
            house_num.set_xalign(0)
            row.append(house_num)

            cusp_pos = house_cusps.get(i, "--")
            sign_sym = "--"
            degree_str = "--"

            if cusp_pos and cusp_pos != '--':
                for sign_name, sign_symbol, _ in SIGNS:
                    abbrev = sign_name[:3]
                    if abbrev in cusp_pos:
                        sign_sym = sign_symbol
                        parts = cusp_pos.split(abbrev)
                        if len(parts) >= 2:
                            degree_str = f"{parts[0]}°{parts[1]}'"
                        break

            sign_lbl = Gtk.Label(label=sign_sym)
            sign_lbl.add_css_class("sign-symbol")
            sign_lbl.set_size_request(50, -1)
            row.append(sign_lbl)

            deg_lbl = Gtk.Label(label=degree_str)
            deg_lbl.add_css_class("degree-text")
            deg_lbl.set_size_request(100, -1)
            deg_lbl.set_xalign(0)
            row.append(deg_lbl)

            self.house_rows_box.append(row)

        # Update chart info
        dt = datetime(
            int(self.year_spin.get_value()),
            int(self.month_spin.get_value()),
            int(self.day_spin.get_value()),
            int(self.hour_spin.get_value()),
            int(self.minute_spin.get_value())
        )

        info_items = [
            ("Date", dt.strftime("%B %d, %Y")),
            ("Time", dt.strftime("%I:%M %p")),
            ("Location", f"{self.lat_entry.get_text()}, {self.lon_entry.get_text()}"),
            ("House System", HOUSE_SYSTEMS[self.house_dropdown.get_selected()][0]),
        ]

        for label, value in info_items:
            row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
            lbl = Gtk.Label(label=f"{label}:")
            lbl.add_css_class("dim-label")
            lbl.set_size_request(100, -1)
            lbl.set_xalign(0)
            row.append(lbl)
            val = Gtk.Label(label=value)
            val.set_xalign(0)
            row.append(val)
            self.chart_info_box.append(row)

        # Build aspect grid
        self.build_aspect_grid(planet_positions)

    def build_aspect_grid(self, planet_positions):
        """Build the aspect grid widget"""
        # Clear existing grid
        while True:
            child = self.aspect_grid_widget.get_first_child()
            if child:
                self.aspect_grid_widget.remove(child)
            else:
                break

        planets_list = [(name, sym) for name, sym, _ in PLANETS[:10]]

        # Header row
        for i, (_, sym) in enumerate(planets_list):
            lbl = Gtk.Label(label=sym)
            lbl.add_css_class("planet-symbol")
            lbl.add_css_class("aspect-cell")
            self.aspect_grid_widget.attach(lbl, i + 1, 0, 1, 1)

        # Header column and grid cells
        for i, (name1, sym1) in enumerate(planets_list):
            lbl = Gtk.Label(label=sym1)
            lbl.add_css_class("planet-symbol")
            lbl.add_css_class("aspect-cell")
            self.aspect_grid_widget.attach(lbl, 0, i + 1, 1, 1)

            for j, (name2, sym2) in enumerate(planets_list):
                if j <= i:
                    # Only show lower triangle
                    cell = Gtk.Label(label="")
                    cell.add_css_class("aspect-cell")
                    self.aspect_grid_widget.attach(cell, j + 1, i + 1, 1, 1)

    def save_profile(self, btn):
        """Save current chart data to a profile"""
        name = self.name_entry.get_text()
        if not name:
            name = f"Chart_{datetime.now().strftime('%Y%m%d_%H%M%S')}"

        profile = ChartProfile(
            name=name,
            month=int(self.month_spin.get_value()),
            day=int(self.day_spin.get_value()),
            year=int(self.year_spin.get_value()),
            hour=int(self.hour_spin.get_value()),
            minute=int(self.minute_spin.get_value()),
            lat=self.lat_entry.get_text(),
            lon=self.lon_entry.get_text(),
            tz=int(self.tz_spin.get_value()),
        )

        filename = f"{name.replace(' ', '_')}.json"
        filepath = self.profiles_dir / filename

        with open(filepath, 'w') as f:
            json.dump(profile.to_dict(), f, indent=2)

        self.load_profiles_list()

    def load_profiles_list(self):
        """Load saved profiles into the list"""
        # Clear existing items
        while True:
            row = self.profiles_list.get_row_at_index(0)
            if row:
                self.profiles_list.remove(row)
            else:
                break

        # Load profiles from directory
        if self.profiles_dir.exists():
            for filepath in sorted(self.profiles_dir.glob("*.json"))[:10]:  # Limit to 10
                try:
                    with open(filepath) as f:
                        data = json.load(f)
                        profile = ChartProfile.from_dict(data)

                    row_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
                    row_box.add_css_class("profile-card")

                    name_lbl = Gtk.Label(label=profile.name or filepath.stem)
                    name_lbl.set_xalign(0)
                    row_box.append(name_lbl)

                    date_str = f"{profile.month}/{profile.day}/{profile.year} {profile.hour}:{profile.minute:02d}"
                    date_lbl = Gtk.Label(label=date_str)
                    date_lbl.add_css_class("dim-label")
                    date_lbl.set_xalign(0)
                    row_box.append(date_lbl)

                    row = Gtk.ListBoxRow()
                    row.set_child(row_box)
                    row.profile_path = filepath
                    self.profiles_list.append(row)
                except Exception as e:
                    print(f"Error loading profile {filepath}: {e}")

    def on_profile_selected(self, listbox, row):
        """Load selected profile"""
        if hasattr(row, 'profile_path'):
            try:
                with open(row.profile_path) as f:
                    data = json.load(f)
                    profile = ChartProfile.from_dict(data)

                self.name_entry.set_text(profile.name)
                self.month_spin.set_value(profile.month)
                self.day_spin.set_value(profile.day)
                self.year_spin.set_value(profile.year)
                self.hour_spin.set_value(profile.hour)
                self.minute_spin.set_value(profile.minute)
                self.lat_entry.set_text(profile.lat)
                self.lon_entry.set_text(profile.lon)
                self.tz_spin.set_value(profile.tz)

                self.generate_chart(None)
            except Exception as e:
                print(f"Error loading profile: {e}")

    def show_load_dialog(self, btn):
        """Show file chooser dialog for loading profiles"""
        dialog = Gtk.FileDialog()
        dialog.set_title("Load Chart Profile")

        filter_json = Gtk.FileFilter()
        filter_json.set_name("JSON files")
        filter_json.add_pattern("*.json")

        filters = Gio.ListStore.new(Gtk.FileFilter)
        filters.append(filter_json)
        dialog.set_filters(filters)

        dialog.set_initial_folder(Gio.File.new_for_path(str(self.profiles_dir)))
        dialog.open(self.win, None, self.on_load_dialog_response)

    def on_load_dialog_response(self, dialog, result):
        try:
            file = dialog.open_finish(result)
            if file:
                filepath = file.get_path()
                with open(filepath) as f:
                    data = json.load(f)
                    profile = ChartProfile.from_dict(data)

                self.name_entry.set_text(profile.name)
                self.month_spin.set_value(profile.month)
                self.day_spin.set_value(profile.day)
                self.year_spin.set_value(profile.year)
                self.hour_spin.set_value(profile.hour)
                self.minute_spin.set_value(profile.minute)
                self.lat_entry.set_text(profile.lat)
                self.lon_entry.set_text(profile.lon)
                self.tz_spin.set_value(profile.tz)

                self.generate_chart(None)
        except Exception as e:
            print(f"Error loading file: {e}")


def main():
    app = AstrologGUI()
    app.run(None)


if __name__ == "__main__":
    main()
