#!/bin/bash
# Apple distribution certificate without a Mac, for the GitHub build. Three steps:
#   tools/make_ios_certificate.sh csr                    private key + request for developer.apple.com
#   tools/make_ios_certificate.sh p12 <file.cer>         certificate from Apple -> .p12 + base64 for the secret
#   tools/make_ios_certificate.sh profile <file.mobileprovision>   base64 of the profile for the secret
# Files go in ~/one-more-tap-ios (or $IOS_SIGNING_DIR). Needs only openssl:
# Linux, macOS, or Git Bash on Windows. Nothing here goes in the repository.
set -euo pipefail
export MSYS_NO_PATHCONV=1  # Git Bash would turn "/CN=..." into a Windows path

DIR="${IOS_SIGNING_DIR:-$HOME/one-more-tap-ios}"
KEY="$DIR/ios_distribution.key"
mkdir -p "$DIR"
chmod 700 "$DIR"

to_base64() {
	base64 < "$1" | tr -d '\n' > "$2"
}

case "${1:-}" in
	csr)
		if [ -e "$KEY" ]; then
			echo "Esiste già $KEY: usa quella (passo p12) o spostala prima di crearne un'altra." >&2
			exit 1
		fi
		read -r -p "Email dell'account Apple Developer: " EMAIL
		read -r -p "Nome e cognome (o nome dell'azienda): " NAME
		openssl req -new -newkey rsa:2048 -nodes -keyout "$KEY" -out "$DIR/ios_distribution.csr" \
			-subj "/emailAddress=$EMAIL/CN=$NAME/C=IT" 2> /dev/null
		chmod 600 "$KEY"
		cat << EOF

Creati:
  $DIR/ios_distribution.csr   la richiesta da caricare su Apple
  $KEY   la chiave privata: non darla a nessuno, serve al passo p12

Ora su developer.apple.com → Certificates, IDs & Profiles → Certificates → +
→ "Apple Distribution" → carica ios_distribution.csr → scarica il certificato
(distribution.cer), poi:
  tools/make_ios_certificate.sh p12 <percorso di distribution.cer>
EOF
		;;
	p12)
		CER="${2:?indica il file .cer scaricato da Apple}"
		if [ ! -e "$KEY" ]; then
			echo "Manca $KEY: il certificato va chiesto con la richiesta creata dal passo csr." >&2
			exit 1
		fi
		TMP="$(mktemp -d)"
		trap 'rm -rf "$TMP"' EXIT
		openssl x509 -inform DER -in "$CER" -out "$TMP/cert.pem" 2> /dev/null \
			|| openssl x509 -in "$CER" -out "$TMP/cert.pem"
		if [ "$(openssl x509 -noout -modulus -in "$TMP/cert.pem")" != "$(openssl rsa -noout -modulus -in "$KEY" 2> /dev/null)" ]; then
			echo "Questo certificato non corrisponde alla chiave in $KEY: è nato da un'altra richiesta." >&2
			exit 1
		fi
		read -r -s -p "Scegli una password per il file .p12: " IOS_P12_PASSWORD
		echo
		if [ -z "$IOS_P12_PASSWORD" ]; then
			echo "La password non può essere vuota." >&2
			exit 1
		fi
		export IOS_P12_PASSWORD
		# The Mac keychain of the build machine does not read OpenSSL 3's default encryption.
		LEGACY=()
		if openssl version | grep -q "^OpenSSL 3"; then
			LEGACY=(-certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -macalg sha1)
		fi
		openssl pkcs12 -export ${LEGACY[@]+"${LEGACY[@]}"} -inkey "$KEY" -in "$TMP/cert.pem" \
			-name "$(openssl x509 -noout -subject -nameopt multiline -in "$TMP/cert.pem" | sed -n 's/^ *commonName *= //p')" \
			-out "$DIR/ios_distribution.p12" -passout env:IOS_P12_PASSWORD
		to_base64 "$DIR/ios_distribution.p12" "$DIR/ios_distribution.p12.base64.txt"
		cat << EOF

Creato $DIR/ios_distribution.p12 (certificato + chiave).
Secret da creare su GitHub (Settings → Secrets and variables → Actions):
  IOS_CERTIFICATE_P12_BASE64  il contenuto di $DIR/ios_distribution.p12.base64.txt
  IOS_CERTIFICATE_PASSWORD    la password che hai appena scelto

Poi crea il profilo (passo "Profilo di distribuzione" in PUBBLICAZIONE.md) e lancia:
  tools/make_ios_certificate.sh profile <percorso del file .mobileprovision>
EOF
		;;
	profile)
		PROFILE="${2:?indica il file .mobileprovision scaricato da Apple}"
		to_base64 "$PROFILE" "$DIR/profile.base64.txt"
		cat << EOF

Secret da creare su GitHub:
  IOS_PROFILE_BASE64  il contenuto di $DIR/profile.base64.txt

Conserva la cartella $DIR in un posto sicuro e cancella i file .base64.txt
dopo averli incollati.
EOF
		;;
	*)
		sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
		exit 1
		;;
esac
