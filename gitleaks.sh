#!/usr/bin/env bash
# Durchsucht die gesamte Git-Historie des aktuellen Repositorys mit gitleaks.
#
# Für GitHub Actions unter Linux x64. Lädt die festgelegte Version aus den offiziellen
# Releases und prüft ihre SHA256-Prüfsumme. So braucht CI keine fremde Action und keine
# Lizenz und läuft auch dort, wo nur GitHub-eigene Actions erlaubt sind.
# Voraussetzung: vollständige Historie (actions/checkout mit fetch-depth: 0).
# Die Version entspricht der lokalen Einrichtung in docs/einrichtung.md.

set -euo pipefail

VERSION=8.30.1
SHA256=551f6fc83ea457d62a0d98237cbad105af8d557003051f41f3e7ca7b3f2470eb
archiv="gitleaks_${VERSION}_linux_x64.tar.gz"
config="$(cd "$(dirname "$0")" && pwd)/.gitleaks.toml"

temp=$(mktemp -d)
trap 'rm -rf "$temp"' EXIT

curl -fsSL -o "$temp/$archiv" "https://github.com/gitleaks/gitleaks/releases/download/v${VERSION}/${archiv}"
echo "${SHA256}  $temp/$archiv" | sha256sum -c -
tar -xzf "$temp/$archiv" -C "$temp" gitleaks

"$temp/gitleaks" git --config "$config" --redact --no-banner -v .
