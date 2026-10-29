#!/bin/bash
# CI (macOS): installs the distribution certificate and the App Store profile
# from the secrets in a temporary keychain, checks that they fit the iOS preset,
# and writes the xcodebuild export options (export-options.plist to make the
# .ipa, upload-options.plist to send it to App Store Connect) in $RUNNER_TEMP/signing.
# Adds TEAM_ID, PROFILE_NAME and KEYCHAIN to $GITHUB_ENV.
# Needs IOS_CERTIFICATE_P12_BASE64, IOS_CERTIFICATE_PASSWORD and IOS_PROFILE_BASE64.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$RUNNER_TEMP/signing"
mkdir -p "$WORK"

BUNDLE_ID="$(sed -n 's/^application\/bundle_identifier="\(.*\)"/\1/p' "$ROOT/export_presets.cfg")"

echo "$IOS_CERTIFICATE_P12_BASE64" | base64 --decode > "$WORK/certificate.p12"
echo "$IOS_PROFILE_BASE64" | base64 --decode > "$WORK/profile.mobileprovision"

# The profile decides team, name and app: check it is the App Store one for this game.
security cms -D -i "$WORK/profile.mobileprovision" > "$WORK/profile.plist"
profile() {
	/usr/libexec/PlistBuddy -c "Print :$1" "$WORK/profile.plist"
}
PROFILE_NAME="$(profile Name)"
PROFILE_UUID="$(profile UUID)"
TEAM_ID="$(profile TeamIdentifier:0)"
APP_ID="$(profile Entitlements:application-identifier)"
if [ "$APP_ID" != "$TEAM_ID.$BUNDLE_ID" ]; then
	echo "::error::Il profilo \"$PROFILE_NAME\" è per $APP_ID, ma il gioco è $TEAM_ID.$BUNDLE_ID"
	exit 1
fi
if profile ProvisionedDevices > /dev/null 2>&1; then
	echo "::error::Il profilo \"$PROFILE_NAME\" è di sviluppo o Ad Hoc: serve un profilo App Store Connect"
	exit 1
fi
for dir in "$HOME/Library/MobileDevice/Provisioning Profiles" \
	"$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"; do
	mkdir -p "$dir"
	cp "$WORK/profile.mobileprovision" "$dir/$PROFILE_UUID.mobileprovision"
done

KEYCHAIN="$WORK/signing.keychain-db"
KEYCHAIN_PASSWORD="$(uuidgen)"
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
security set-keychain-settings -lut 21600 "$KEYCHAIN"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN"
# Apple's intermediate certificate, so that codesign can trust the distribution
# one even where the runner image lacks it.
if curl -fsSL -o "$WORK/AppleWWDRCAG3.cer" https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer; then
	security import "$WORK/AppleWWDRCAG3.cer" -k "$KEYCHAIN" > /dev/null || true
fi
security import "$WORK/certificate.p12" -P "$IOS_CERTIFICATE_PASSWORD" -A -t cert -f pkcs12 -k "$KEYCHAIN"
security set-key-partition-list -S apple-tool:,apple: -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN" > /dev/null
KEYCHAINS=("$KEYCHAIN")
while IFS= read -r line; do
	line="${line//\"/}"
	KEYCHAINS+=("${line#"${line%%[![:space:]]*}"}")
done < <(security list-keychains -d user)
security list-keychains -d user -s "${KEYCHAINS[@]}"

if ! security find-identity -v -p codesigning "$KEYCHAIN" | grep -q "Apple Distribution"; then
	security find-identity -p codesigning "$KEYCHAIN"
	echo "::error::Nel certificato non c'è un'identità \"Apple Distribution\" valida (scaduto, revocato o di un altro tipo?)"
	exit 1
fi

xml() {
	printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}
for destination in export upload; do
	cat > "$WORK/$destination-options.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>destination</key>
	<string>$destination</string>
	<key>teamID</key>
	<string>$TEAM_ID</string>
	<key>signingStyle</key>
	<string>manual</string>
	<key>signingCertificate</key>
	<string>Apple Distribution</string>
	<key>provisioningProfiles</key>
	<dict>
		<key>$(xml "$BUNDLE_ID")</key>
		<string>$(xml "$PROFILE_NAME")</string>
	</dict>
	<key>manageAppVersionAndBuildNumber</key>
	<false/>
	<key>uploadSymbols</key>
	<true/>
</dict>
</plist>
EOF
	plutil -lint "$WORK/$destination-options.plist"
done

{
	echo "TEAM_ID=$TEAM_ID"
	echo "PROFILE_NAME=$PROFILE_NAME"
	echo "KEYCHAIN=$KEYCHAIN"
} >> "$GITHUB_ENV"
echo "Firma pronta: team $TEAM_ID, profilo \"$PROFILE_NAME\" per $BUNDLE_ID"
