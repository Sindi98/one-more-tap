#!/bin/bash
# Creates the Android upload key (alias "upload", RSA 2048, valid ~27 years) and
# the base64 text for the ANDROID_KEYSTORE_BASE64 secret of the GitHub build.
# Needs only openssl: Linux, macOS, or Git Bash on Windows.
# The key never goes in the repository: keep the file and its password safe.
# Usage: tools/make_android_keystore.sh [output folder, default: home folder]
set -euo pipefail
export MSYS_NO_PATHCONV=1  # Git Bash would turn "/CN=..." into a Windows path

OUT_DIR="${1:-$HOME}"
KEYSTORE="$OUT_DIR/one-more-tap-upload.p12"
if [ -e "$KEYSTORE" ]; then
	echo "Esiste già $KEYSTORE: non sostituire mai una chiave che hai già usato su Google Play." >&2
	exit 1
fi

read -r -s -p "Scegli una password (almeno 6 caratteri): " KEYSTORE_PASSWORD
echo
read -r -s -p "Ripetila: " AGAIN
echo
if [ "$KEYSTORE_PASSWORD" != "$AGAIN" ]; then
	echo "Le due password sono diverse." >&2
	exit 1
fi
if [ ${#KEYSTORE_PASSWORD} -lt 6 ]; then
	echo "La password deve avere almeno 6 caratteri." >&2
	exit 1
fi
export KEYSTORE_PASSWORD

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
openssl req -x509 -newkey rsa:2048 -nodes -days 10000 -subj "/CN=One More Tap" \
	-keyout "$TMP/key.pem" -out "$TMP/cert.pem" 2> /dev/null
# Same password for the file and the key: Godot and Gradle use one for both.
openssl pkcs12 -export -name upload -inkey "$TMP/key.pem" -in "$TMP/cert.pem" \
	-out "$KEYSTORE" -passout env:KEYSTORE_PASSWORD
base64 < "$KEYSTORE" | tr -d '\n' > "$KEYSTORE.base64.txt"

cat << EOF

Chiave creata: $KEYSTORE
Salvala con la password in un posto sicuro (gestore di password + backup).
Se la perdi, Google può sostituirla, ma ci vogliono giorni.

Secret da creare su GitHub (Settings → Secrets and variables → Actions):
  ANDROID_KEYSTORE_BASE64    il contenuto di $KEYSTORE.base64.txt
  ANDROID_KEYSTORE_PASSWORD  la password che hai appena scelto

Poi cancella $KEYSTORE.base64.txt: serve solo per incollarlo.
EOF
