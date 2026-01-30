# Hermetic Desktop Rice

A mystical, arcane desktop theming system for NixOS + niri, inspired by hermetic traditions, alchemy, and ancient grimoires.

## Overview

This project transforms the NixOS desktop environment into a cohesive hermetic/wizard aesthetic using:
- **Stylix** for system-wide theming
- **Niri** scrollable tiling Wayland compositor
- **Waybar** status bar with custom widgets
- **Fuzzel** application launcher
- **Alacritty** terminal
- **Starship** shell prompt

## Color Scheme: Hermetic Arcanum

Custom base16 color scheme located at `modules/stylix/hermetic-arcanum.yaml`:

| Color   | Hex       | Purpose                        |
|---------|-----------|--------------------------------|
| base00  | `#0d0d14` | Deep void black (background)   |
| base01  | `#1a1a2e` | Obsidian panel background      |
| base02  | `#2d2d44` | Selection/highlight            |
| base03  | `#4a4a6a` | Comments, muted text           |
| base04  | `#8b8bab` | Secondary text                 |
| base05  | `#c9c9d9` | Primary text                   |
| base06  | `#e0e0ec` | Light foreground               |
| base07  | `#f5f5ff` | Brightest text                 |
| base08  | `#8b2252` | Deep crimson (errors)          |
| base09  | `#d4a017` | Alchemical gold (accents)      |
| base0A  | `#c9a227` | Amber/sulfur (types)           |
| base0B  | `#5e7a5e` | Verdigris green (strings)      |
| base0C  | `#6b8e9f` | Mercury silver-blue (cyan)     |
| base0D  | `#7b68ab` | Royal purple (functions)       |
| base0E  | `#9b59b6` | Amethyst purple (keywords)     |
| base0F  | `#6e4a3a` | Burnt umber (special)          |

## Module Structure

```
modules/
├── stylix/
│   ├── default.nix           # Stylix config with fonts, colors, opacity
│   └── hermetic-arcanum.yaml # Custom base16 color scheme
├── fonts/
│   └── default.nix           # EB Garamond, Inter, Iosevka Nerd Font
├── desktop-presets/
│   └── niri/
│       └── default.nix       # Niri, Waybar, Fuzzel configuration
├── alacritty/
│   └── default.nix           # Terminal configuration
├── astrology/
│   ├── default.nix           # Astrology tools module
│   ├── planetary-hours.py    # Planetary hours calculator
│   └── astrolog-gui.py       # GTK4 GUI wrapper for astrolog
└── users/metamageia/
    └── home.nix              # Starship prompt, GTK icons
```

## Key Components

### Stylix Configuration (`modules/stylix/default.nix`)
- Base16 scheme: `hermetic-arcanum.yaml`
- Polarity: dark
- Opacity: desktop 0.90, terminal 0.92, applications 0.95
- Cursor: phinger-cursors-light (size 24)
- Fonts:
  - Serif: EB Garamond
  - Sans: Inter
  - Mono: Iosevka Nerd Font
  - Emoji: Noto Color Emoji

### Niri Window Manager (`modules/desktop-presets/niri/default.nix`)
- Gaps: 12px
- Focus ring: 3px width, alchemical gold (`#d4a017`)
- Window borders: 2px, royal purple (`#7b68ab`)
- Corner radius: 10px
- Window opacity: 0.93 (except Zen browser)

### Waybar Status Bar
- Position: top with 8px margin
- Height: 36px
- Modules:
  - Left: `custom/planetary-hour`, `niri/workspaces`
  - Center: `clock` (with moon/sun symbols)
  - Right: `pulseaudio`, `cpu`, `memory`, `network`, `tray`
- Planet-specific colors for planetary hour widget

### Fuzzel Launcher
- Font: EB Garamond (size 14)
- Prompt: Mercury symbol
- Border: 2px, radius 12px
- Colors match hermetic theme

### Starship Prompt (`modules/users/metamageia/home.nix`)
- Success symbol: Mercury (☿) in gold
- Error symbol: Pentagram in crimson
- Directory: Pentagram prefix in purple
- Git branch: Mercury silver-blue

## Astrology Module (`modules/astrology/`)

### Planetary Hours Widget
- Location: El Dorado, KS (37.8172° N, 96.8622° W)
- Uses PyEphem for sunrise/sunset calculations
- Implements Chaldean planetary hour order
- Updates every 60 seconds
- Shows ruling planet with symbol and tooltip

### Installed Tools
- **Astrolog** - Classic CLI astrology program
- **Astrolog-GUI** - Custom GTK4 wrapper for astrolog (see below)
- **Stellarium** - Desktop planetarium
- **Astroterm** - Terminal celestial viewer

### Astrolog GUI (`modules/astrology/astrolog-gui.py`)

A simple GTK4 wrapper for generating natal charts with astrolog.

**Features:**
- Birth date/time input with spin buttons
- Location presets (El Dorado KS, NYC, London, Paris) or custom lat/long
- Timezone selection
- "Set to Now" button for current moment charts
- White/dark background toggle
- House info toggle
- Generates 700x700 bitmap chart wheel
- Dark theme matching hermetic aesthetic

**Technical:**
- Uses `astrolog -X -Xb` for bitmap output
- Python GTK4 with pygobject3 and pycairo
- Combined Python environment with ephem for both scripts
- Chart displayed in scrollable picture widget

**Colors:**
- Background: `#0d0d14` (void black)
- Inputs: `#1a1a2e` border with `#7b68ab` (purple)
- Buttons: `#7b68ab` (purple)
- Title: `#d4a017` (gold)
- Section headers: `#c9a227` (amber)

## Theming Symbols Used

| Symbol | Meaning              | Usage                    |
|--------|----------------------|--------------------------|
| ☽      | Moon                 | Waybar clock (night)     |
| ☉      | Sun                  | Waybar clock (day)       |
| ☿      | Mercury              | Fuzzel prompt, starship  |
| ♀      | Venus                | Planetary hours          |
| ♂      | Mars                 | Planetary hours          |
| ♃      | Jupiter              | Planetary hours          |
| ♄      | Saturn               | Planetary hours          |
| ⛤      | Pentagram            | Directory prefix         |
| ⛧      | Inverted pentagram   | Error symbol             |

## Future Development Ideas

### Enhancements
- [ ] Add moon phase widget to waybar
- [ ] Create astrological chart display widget
- [ ] Add planetary day indicator
- [ ] Implement void-of-course moon alerts
- [ ] Add current zodiac sign of moon
- [ ] Create election finder for auspicious times

### Visual Improvements
- [ ] Custom SDDM login theme with sigils
- [ ] Animated wallpaper with planetary glyphs
- [ ] Custom notification styling with arcane borders
- [ ] Rofi/fuzzel theme with astrological categories

### Tools Integration
- [ ] Script to generate daily planetary hour schedule
- [x] Integration with astrolog for birth chart display (astrolog-gui)
- [ ] Ephemeris lookup shortcuts
- [ ] Tarot card of the day widget
- [ ] Transit chart generation
- [ ] Synastry/composite chart support

### Configuration
- [ ] Make location configurable via userValues
- [ ] Add timezone handling for planetary calculations
- [ ] Create presets for different hermetic color variations
- [ ] Add optional components (minimal vs full rice)

## Commands

```bash
# Rebuild and apply
nh os switch

# Build without switching
nh os build

# Format nix files
alejandra .

# Test planetary hours script
planetary-hours

# Launch astrology tools
astrolog          # CLI astrology
astrolog-gui      # GTK4 natal chart generator
stellarium        # Planetarium
astroterm         # Terminal celestial viewer
```

## Dependencies

The rice relies on these flake inputs:
- `stylix` - System-wide theming
- `niri-flake` - Niri compositor
- `home-manager` - User configuration

Key packages:
- `python3Packages.ephem` - Astronomical calculations
- `python3Packages.pygobject3` - GTK4 Python bindings
- `python3Packages.pycairo` - Cairo graphics for Python
- `gtk4`, `gobject-introspection` - GTK4 runtime
- `astrolog` - Astrology calculations engine
- `phinger-cursors` - Cursor theme
- `papirus-icon-theme` - GTK icons
- `eb-garamond`, `inter`, `nerd-fonts.iosevka` - Fonts
