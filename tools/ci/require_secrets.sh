#!/bin/bash
# CI: stops with a clear message when a GitHub secret the build needs is empty.
# Usage: tools/ci/require_secrets.sh NAME... (each secret passed to the step as an env var)

missing=()
for name in "$@"; do
	[ -n "${!name:-}" ] || missing+=("$name")
done
if [ ${#missing[@]} -gt 0 ]; then
	echo "::error::Mancano i secret ${missing[*]}: vedi PUBBLICAZIONE.md, passo 10"
	exit 1
fi
