#!/bin/bash
# Installs the native libraries of the AdMob plugin in addons/admob/<platform>/bin,
# as Project → Tools → AdMob Manager → Download & Install does in the editor.
# They are not in the repository (addons/admob/*/.gitignore).
# Usage: tools/ci/install_admob.sh android|ios
set -euo pipefail

PLATFORM="${1:?usage: install_admob.sh android|ios}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

PLUGIN_VERSION="v$(sed -n 's/^version="\(.*\)"/\1/p' "$ROOT/addons/admob/plugin.cfg")"
# The plugin publishes one zip per Godot version, named after major.minor.patch.
GODOT_VERSION="${GODOT_VERSION:-4.7}"
case "$GODOT_VERSION" in
	*.*.*) ENGINE="v$GODOT_VERSION" ;;
	*) ENGINE="v$GODOT_VERSION.0" ;;
esac

ZIP="$PLATFORM-template-$ENGINE.zip"
BIN="$ROOT/addons/admob/$PLATFORM/bin"
TMP="$(mktemp -d)"

curl -fsSL --retry 3 -o "$TMP/$ZIP" \
	"https://github.com/poingstudios/godot-admob-plugin/releases/download/$PLUGIN_VERSION/$ZIP"
rm -rf "$BIN"
mkdir -p "$BIN"
unzip -q -o "$TMP/$ZIP" -d "$BIN"
rm -rf "$TMP"

# The file the plugin writes after installing: it tells the exporter which version is there.
cat > "$BIN/package.gd" << EOF
# This file is dynamically generated.
# It defines the current installed version of the platform plugin.
# Do not modify this manually.

const VERSION := "$PLUGIN_VERSION"
EOF

echo "AdMob $PLUGIN_VERSION for $PLATFORM installed in addons/admob/$PLATFORM/bin"
