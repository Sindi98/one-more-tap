#!/bin/bash
# Downloads Godot for the CI builds (.github/workflows/mobile.yml), on Linux or
# macOS, checks it against the release's SHA512 sums and writes its path to
# $GITHUB_ENV as GODOT. With "templates" it also installs the export templates.
# Usage: tools/ci/install_godot.sh [templates]
set -euo pipefail

VERSION="${GODOT_VERSION:-4.7}"
TAG="$VERSION-stable"
URL="https://github.com/godotengine/godot/releases/download/$TAG"
DEST="${RUNNER_TEMP:-/tmp}/godot"
mkdir -p "$DEST"
cd "$DEST"

case "$(uname -s)" in
	Linux)
		EDITOR_ZIP="Godot_v${TAG}_linux.x86_64.zip"
		GODOT="$DEST/Godot_v${TAG}_linux.x86_64"
		TEMPLATES_DIR="$HOME/.local/share/godot/export_templates/$VERSION.stable"
		;;
	Darwin)
		EDITOR_ZIP="Godot_v${TAG}_macos.universal.zip"
		GODOT="$DEST/Godot.app/Contents/MacOS/Godot"
		TEMPLATES_DIR="$HOME/Library/Application Support/Godot/export_templates/$VERSION.stable"
		;;
	*)
		echo "Unsupported system: $(uname -s)" >&2
		exit 1
		;;
esac

FILES=("$EDITOR_ZIP")
if [ "${1:-}" = "templates" ]; then
	FILES+=("Godot_v${TAG}_export_templates.tpz")
fi

curl -fsSL -o SHA512-SUMS.txt "$URL/SHA512-SUMS.txt"
for file in "${FILES[@]}"; do
	curl -fsSL --retry 3 -o "$file" "$URL/$file"
	grep " $file\$" SHA512-SUMS.txt | shasum -a 512 -c -
done

unzip -q -o "$EDITOR_ZIP"
"$GODOT" --version

if [ "${1:-}" = "templates" ]; then
	unzip -q -o "Godot_v${TAG}_export_templates.tpz"
	mkdir -p "$(dirname "$TEMPLATES_DIR")"
	rm -rf "$TEMPLATES_DIR"
	mv templates "$TEMPLATES_DIR"
	rm "Godot_v${TAG}_export_templates.tpz"
fi

if [ -n "${GITHUB_ENV:-}" ]; then
	echo "GODOT=$GODOT" >> "$GITHUB_ENV"
else
	echo "GODOT=$GODOT"
fi
