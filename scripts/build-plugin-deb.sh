#!/usr/bin/env bash
set -e

PLUGIN="$1"
if [ -z "$PLUGIN" ]; then
    echo "Usage: $0 <plugin-name>"
    exit 1
fi

PLUGIN_DIR="$(cd "$PLUGIN" && pwd)"
if [ ! -f "$PLUGIN_DIR/plugin.yaml" ]; then
    echo "Error: $PLUGIN_DIR/plugin.yaml not found!"
    exit 1
fi

# Extract metadata using python or grep
VERSION=$(python3 -c "
import yaml, sys
try:
    with open('$PLUGIN_DIR/plugin.yaml') as f:
        data = yaml.safe_load(f)
        print(data.get('metadata', {}).get('version', '0.1.0'))
except Exception:
    print('0.1.0')
" 2>/dev/null || grep -E '^\s*version:' "$PLUGIN_DIR/plugin.yaml" | head -n1 | awk '{print $2}' | tr -d '"'\''')

[ -z "$VERSION" ] && VERSION="0.1.0"
CLEAN_VERSION=$(echo "$VERSION" | sed 's/^v//')

PKG_NAME="m3tal-plugin-$PLUGIN"
DEB_NAME="${PKG_NAME}_${CLEAN_VERSION}_amd64.deb"

echo "📦 Packaging $PKG_NAME v${CLEAN_VERSION}..."

# Build plugin if Makefile exists
if [ -f "$PLUGIN_DIR/Makefile" ]; then
    echo "🔨 Running build in $PLUGIN_DIR..."
    make -C "$PLUGIN_DIR" build
fi

STAGE_DIR=$(mktemp -d /tmp/m3tal-plugin-deb.XXXXXX)
trap 'rm -rf "$STAGE_DIR"' EXIT

# Create standard package layout
mkdir -p "$STAGE_DIR/DEBIAN"
mkdir -p "$STAGE_DIR/usr/lib/m3tal/plugins/$PLUGIN"
mkdir -p "$STAGE_DIR/etc/m3tal/plugins/$PLUGIN"

# Copy payload
cp "$PLUGIN_DIR/plugin.yaml" "$STAGE_DIR/usr/lib/m3tal/plugins/$PLUGIN/"
[ -d "$PLUGIN_DIR/bin" ] && cp -r "$PLUGIN_DIR/bin" "$STAGE_DIR/usr/lib/m3tal/plugins/$PLUGIN/"
[ -d "$PLUGIN_DIR/ui/dist" ] && mkdir -p "$STAGE_DIR/usr/lib/m3tal/plugins/$PLUGIN/ui" && cp -r "$PLUGIN_DIR/ui/dist" "$STAGE_DIR/usr/lib/m3tal/plugins/$PLUGIN/ui/"
[ -d "$PLUGIN_DIR/config" ] && cp -r "$PLUGIN_DIR/config" "$STAGE_DIR/usr/lib/m3tal/plugins/$PLUGIN/"

# Set permissions
find "$STAGE_DIR" -type d -exec chmod 755 {} +
find "$STAGE_DIR/usr/lib/m3tal/plugins/$PLUGIN" -type f -exec chmod 644 {} +
[ -d "$STAGE_DIR/usr/lib/m3tal/plugins/$PLUGIN/bin" ] && find "$STAGE_DIR/usr/lib/m3tal/plugins/$PLUGIN/bin" -type f -exec chmod 755 {} +

# Generate DEBIAN/control
cat << EOF > "$STAGE_DIR/DEBIAN/control"
Package: $PKG_NAME
Version: $CLEAN_VERSION
Architecture: amd64
Maintainer: M3tal Community <maintainers@m3tal.io>
Section: utils
Priority: optional
Depends: m3tal (>= 0.3.0)
Description: M3TAL official plugin for $PLUGIN
 Standalone external plugin for the M3TAL Linux Supervisor and Control Plane.
EOF

chmod 644 "$STAGE_DIR/DEBIAN/control"

# Build debian package
dpkg-deb --build --root-owner-group "$STAGE_DIR" "$DEB_NAME"
sha256sum "$DEB_NAME" > "${DEB_NAME}.sha256"

echo "✅ Successfully built: $DEB_NAME ($(du -h "$DEB_NAME" | cut -f1))"
