# Scripts

This directory contains utility scripts for the Vehicle Controller project.

## Available Scripts

### `dashboard.py`

A real-time terminal dashboard for monitoring vehicle control data from the Flutter app.

**Usage:**
```bash
# From project root
python scripts/dashboard.py

# With custom host/port
python scripts/dashboard.py --host 0.0.0.0 --port 8080
```

**Features:**
- Real-time data visualization
- Beautiful terminal UI using Rich library
- Connection status monitoring
- Control state display (gas, brake, steering, gear, etc.)

See [README_DASHBOARD.md](README_DASHBOARD.md) for detailed documentation.

**Requirements:**
- Python 3.7+
- `rich` library (install via `pip install -r requirements.txt`)

---

### `generate_logo.py`

Generates the app logo icon files in various sizes.

**Usage:**
```bash
# From project root
python scripts/generate_logo.py
```

**What it does:**
- Creates a simple steering wheel logo design
- Generates logo files in multiple sizes (128px, 256px, 512px, 1024px)
- Saves files to `assets/icons/` directory
- Uses the app's brand color (#01252c) as background

**Requirements:**
- Python 3.7+
- `Pillow` library (install via `pip install Pillow`)

**Note:** Run this script if you need to regenerate the app logo. The generated logo will be used by `flutter_launcher_icons` to create app icons.

---

## Running Scripts

All scripts should be run from the project root directory:

```bash
# Example
cd /path/to/vehicle_controller
python scripts/dashboard.py
```

This ensures that relative paths (like `../assets/icons/`) work correctly.
