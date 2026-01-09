#!/bin/bash

set -e  # Exit on error

# ===== Validation =====
# Verify user is set
if [ -z "$USER" ]; then
    echo "Error: USER environment variable not set" >&2
    exit 1
fi

# Verify home directory exists
if [ ! -d "$HOME" ]; then
    echo "Error: HOME directory '$HOME' does not exist" >&2
    exit 1
fi

# ===== Directory Creation =====
# Create applications directory if it doesn't exist
applications_dir="$HOME/.local/share/applications"
if [ ! -d "$applications_dir" ]; then
    mkdir -p "$applications_dir" || {
        echo "Error: Could not create $applications_dir" >&2
        exit 1
    }
fi

# ===== Validate Dependencies =====
# Check if Alacritty is installed
if ! command -v alacritty &> /dev/null; then
    echo "Error: Alacritty is not installed. Install it first:" >&2
    echo "  sudo apt install -y alacritty" >&2
    exit 1
fi

# ===== Validate Alacritty Config =====
alacritty_config="$HOME/.config/alacritty/pane.toml"
if [ ! -f "$alacritty_config" ]; then
    echo "Warning: Alacritty config not found at $alacritty_config" >&2
    echo "         Using default Alacritty config instead" >&2
    alacritty_config=""
fi

# ===== Validate Icon =====
icon_path="$HOME/.local/share/omakub/applications/icons/Omakub.png"
if [ ! -f "$icon_path" ]; then
    echo "Warning: Icon not found at $icon_path" >&2
    icon_path=""  # Use default icon if not found
fi

# ===== Build Exec Command =====
exec_cmd="alacritty"
if [ -n "$alacritty_config" ]; then
    exec_cmd="$exec_cmd --config-file $alacritty_config"
fi
exec_cmd="$exec_cmd --class=Omakub --title=Omakub -e bash -l -c omakub"

# ===== Create Desktop Entry =====
desktop_file="$applications_dir/Omakub.desktop"

cat > "$desktop_file" <<EOF
[Desktop Entry]
Version=1.0
Name=Omakub
Comment=Omakub System Control
Exec=$exec_cmd
Terminal=false
Type=Application
Icon=$icon_path
Categories=Development;System;GTK;
StartupNotify=false
Keywords=omakub;install;development;

# Additional metadata
GenericName=System Configuration
X-Omakub-Version=1.0
EOF

# ===== Validate Desktop File =====
if [ ! -f "$desktop_file" ]; then
    echo "Error: Failed to create desktop file at $desktop_file" >&2
    exit 1
fi

# ===== Set Permissions =====
chmod 644 "$desktop_file" || {
    echo "Error: Could not set permissions on $desktop_file" >&2
    exit 1
}

# ===== Update Desktop Database =====
# This makes the new application appear in menus
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$applications_dir" 2>/dev/null || true
fi