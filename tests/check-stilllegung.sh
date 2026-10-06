#!/usr/bin/env bash
# Prüft Stilllegung mit synthetischen Dokumenten in einem isolierten Verzeichnis.
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
temp_base=$(cd "${TMPDIR:-/tmp}" && pwd -P)
test_dir=$(mktemp -d "$temp_base/it-doc-stilllegung.XXXXXX")
cleanup() {
  case "$test_dir" in
    "$temp_base"/it-doc-stilllegung.?*) rm -rf -- "$test_dir" ;;
    *) echo "Unsicherer temporärer Pfad: $test_dir" >&2; return 1 ;;
  esac
}
trap cleanup EXIT

fail() { echo "FEHLER im Test: $*" >&2; exit 1; }
contains() { grep -Fq -- "$2" "$1" || fail "Nicht gefunden in $1: $2"; }
absent() { if grep -Fq -- "$2" "$1"; then fail "Unerwartet in $1: $2"; fi; }
today=$(date +%F)
if date --version >/dev/null 2>&1; then
  six_months=$(date -d '-6 months' +%F)
else
  six_months=$(date -v-6m +%F)
fi

# org, system, entry (leer für Systemblatt), status, datum, optional nachfolger
document() {
  local org="$1" system="$2" entry="$3" status="$4" datum="$5" successor="${6:-}"
  local dir="$org/$system" heading
  [ -z "$entry" ] || dir="$dir/$entry"
  mkdir -p "$dir"
  {
    printf '%s\n' '---' "organisation: $org" "system: $system" "status: $status" "pruefdatum: $datum"
    [ -z "$successor" ] || printf 'nachfolger: %s\n' "$successor"
    printf '%s\n\n' '---'
    printf '# %s\n\n' "${entry:-$system}"
    if [ -n "$entry" ]; then
      printf '> **Änderung:** Testdokument.\n\n'
      for heading in Eckdaten Zweck Voraussetzungen 'Umgesetzte Änderungen' Betriebsablauf Verifikation Fehlerbehebung Rückbau 'Sicherheits- und Datenschutzhinweise' Änderungsverlauf; do
        printf '## %s\n\n' "$heading"
      done
      printf '### Geprüft\n\n### Nicht geprüft\n'
    else
      for heading in Eckdaten Zugang Hinweise Änderungsverlauf; do
        printf '## %s\n\n' "$heading"
      done
    fi
  } >"$dir/README.md"
}

prepare() {
  mkdir -p "$test_dir/$1/tooling"
  cp "$repo/check.sh" "$test_dir/$1/tooling/check.sh"
  cd "$test_dir/$1"
}

# Konfiguration wie im Makefile eines Dokumentations-Repositorys.
export ORGANISATIONEN="privat firma verein"
export BEKANNTE_ORGANISATIONEN="$ORGANISATIONEN extern"
# Mit Umlauten: Ein korrekt kodierter Wert muss unverändert im Index landen.
export INDEX_BESCHREIBUNG="Testdokumentation für ASKÖ."

# Setzt dient in der Frontmatter eines vorhandenen Dokuments.
dient() { sed "s/^pruefdatum:.*/&\ndient: [$2]/" "$1" >modified && mv modified "$1"; }

prepare valid
document privat z-laufend '' 'Aktiv und verifiziert' "$six_months"
document privat z-laufend aktiv-alt 'Aktiv und verifiziert' 2000-01-01
document privat z-laufend aktiv-sechs-monate 'Aktiv und verifiziert' "$six_months"
document privat z-laufend teilweise-alt 'Teilweise aktiv' "$six_months"
document privat z-laufend blockiert-alt Blockiert "$six_months"
document privat z-laufend teilweise-frisch 'Teilweise aktiv' "$today"
document privat z-laufend deaktiviert Deaktiviert 2000-01-01
document privat z-laufend veraltet Veraltet 2000-01-01 privat/z-laufend/aktiv-alt
document privat v-veraltet '' Veraltet 2000-01-01 privat/z-laufend
document privat v-veraltet aktiv-alt 'Aktiv und verifiziert' 2000-01-01
document privat a-stillgelegt '' Deaktiviert 2000-01-01
document privat a-stillgelegt aktiv 'Aktiv und verifiziert' 2000-01-01
document privat a-stillgelegt teilweise 'Teilweise aktiv' 2000-01-01
document privat a-stillgelegt blockiert Blockiert 2000-01-01
document privat a-stillgelegt deaktiviert Deaktiviert 2000-01-01
document privat a-stillgelegt veraltet Veraltet 2000-01-01 privat/z-laufend/aktiv-alt
document firma leer '' Deaktiviert 2000-01-01
document verein laufend '' Blockiert "$six_months"
document verein laufend fremd-dient 'Aktiv und verifiziert' "$today"
dient verein/laufend/fremd-dient/README.md 'privat, extern'
# Großgeschriebener Titel: Byteweise steht er vor den kleingeschriebenen, in einer UTF-8-Locale oft dahinter.
document privat z-laufend Zeta 'Aktiv und verifiziert' "$today"
# Bindestrich-Paar mit Alterswarnung: Byteweise steht nas-backup vorn, in einer UTF-8-Locale nasa.
document privat z-laufend nas-backup 'Aktiv und verifiziert' 2000-01-01
document privat z-laufend nasa 'Aktiv und verifiziert' 2000-01-01
locale_utf8=$(locale -a 2>/dev/null | grep -i -m1 -E '^(en_US|de_DE)\.utf-?8$' || true)

find privat firma verein -type f -exec cksum {} \; | sort >before
# Die Beschreibung so, wie ein natives Windows-make sie über CP1252 verfälscht weiterreicht.
if ! INDEX_BESCHREIBUNG='Testdokumentation fÃ¼r ASKÃ–.' LC_ALL="${locale_utf8:-C}" bash tooling/check.sh >stdout 2>stderr; then
  cat stderr >&2; fail 'Gültige Dokumente abgelehnt'
fi
find privat firma verein -type f -exec cksum {} \; | sort >after
cmp -s before after || fail 'Prüfung hat Quelldokumente verändert'

[ "$(grep -c '^WARNUNG ' stderr)" -eq 7 ] || fail 'Genau sieben Alterswarnungen erwartet'
awk '/^## Warnungen$/ {inside=1; next} /^## / {inside=0} inside && /^- /' README.md >warnungen-index
contains warnungen-index 'privat/z-laufend/nas-backup/README.md'
LC_ALL=C sort -c warnungen-index 2>/dev/null || fail 'Warnungen im Index müssen unabhängig von der Locale byteweise sortiert sein'
contains stderr "privat/z-laufend/aktiv-alt/README.md: Prüfdatum 2000-01-01 ist älter als 12 Monate"
contains stderr "privat/v-veraltet/aktiv-alt/README.md: Prüfdatum 2000-01-01 ist älter als 12 Monate"
contains stderr "privat/z-laufend/teilweise-alt/README.md: Prüfdatum $six_months ist älter als 3 Monate"
contains stderr "privat/z-laufend/blockiert-alt/README.md: Prüfdatum $six_months ist älter als 3 Monate"
contains stderr "verein/laufend/README.md: Prüfdatum $six_months ist älter als 3 Monate"

awk '/^## privat$/ {inside=1; next} /^## / {inside=0} inside' README.md >privat-index
awk '/^## firma$/ {inside=1; next} /^## / {inside=0} inside' README.md >firma-index
awk '/^## verein$/ {inside=1; next} /^## / {inside=0} inside' README.md >verein-index
contains privat-index '### [z-laufend](privat/z-laufend/README.md)'
contains privat-index '### [v-veraltet](privat/v-veraltet/README.md)'
contains privat-index '### Stillgelegte Systeme'
contains privat-index '#### [a-stillgelegt](privat/a-stillgelegt/README.md)'
contains privat-index '| Eintrag | Damaliger Status |'
contains privat-index '| [aktiv](privat/a-stillgelegt/aktiv/README.md) | Aktiv und verifiziert | 2000-01-01 |'
contains privat-index '| [blockiert](privat/a-stillgelegt/blockiert/README.md) | Blockiert | 2000-01-01 |'
contains privat-index '| Eintrag | Status |'
awk '/\[Zeta\]/ {upper=NR} /\[aktiv-alt\]\(privat\/z-laufend/ {lower=NR} END {exit !(upper && lower && upper < lower)}' privat-index ||
  fail 'Einträge müssen unabhängig von der Locale byteweise sortiert sein'
awk '
  /^### \[z-laufend\]/ {active=NR}
  /^### \[v-veraltet\]/ {outdated=NR}
  /^### Stillgelegte Systeme$/ {group=NR}
  /^#### \[a-stillgelegt\]/ {retired=NR}
  END {exit !(active && outdated && active < group && outdated < group && group < retired)}
' privat-index || fail 'Laufende Systeme müssen vor der Stilllegungsgruppe stehen'
contains firma-index '### Stillgelegte Systeme'
contains firma-index '#### [leer](firma/leer/README.md)'
absent firma-index '| Eintrag |'
absent verein-index 'Stillgelegte Systeme'
contains verein-index '| privat, extern |'
contains README.md 'Testdokumentation für ASKÖ.'
absent README.md 'Ã'

prepare invalid
document privat stillgelegt '' Deaktiviert 2000-01-01
document privat stillgelegt yaml Deaktiviert 2000-01-01
document privat stillgelegt status Unbekannt 2000-01-01
document privat stillgelegt datum Deaktiviert 2000-02-30
document privat stillgelegt nachfolger-fehlt Veraltet 2000-01-01
document privat stillgelegt nachfolger-kaputt Veraltet 2000-01-01 privat/fehlt/ersatz
document privat stillgelegt link Deaktiviert 2000-01-01
document privat stillgelegt abschnitt Deaktiviert 2000-01-01
document privat stillgelegt frontmatter Deaktiviert 2000-01-01
document privat stillgelegt dient-unbekannt Deaktiviert 2000-01-01
dient privat/stillgelegt/dient-unbekannt/README.md unbekannt

# Jede defekte Datei behält ihren eigenen Pfad, damit alle Fehler nachweisbar sind.
sed 's/^status:.*/status: [/' privat/stillgelegt/yaml/README.md >modified
mv modified privat/stillgelegt/yaml/README.md
printf '\n[Fehlendes Ziel](fehlt.md)\n' >>privat/stillgelegt/link/README.md
sed '/^## Zweck$/d' privat/stillgelegt/abschnitt/README.md >modified
mv modified privat/stillgelegt/abschnitt/README.md
sed '1d' privat/stillgelegt/frontmatter/README.md >modified
mv modified privat/stillgelegt/frontmatter/README.md

result=0
bash tooling/check.sh >stdout 2>stderr || result=$?
[ "$result" -eq 1 ] || fail "Ungültige historische Dokumente müssen Exit 1 liefern, erhalten: $result"
contains stderr 'privat/stillgelegt/yaml/README.md: Frontmatter ist kein gültiges YAML'
contains stderr 'privat/stillgelegt/status/README.md: status'
contains stderr 'privat/stillgelegt/datum/README.md: pruefdatum'
contains stderr 'privat/stillgelegt/nachfolger-fehlt/README.md: Status Veraltet braucht das Feld nachfolger'
contains stderr 'privat/stillgelegt/nachfolger-kaputt/README.md: nachfolger'
contains stderr 'privat/stillgelegt/link/README.md: Link zeigt ins Leere: fehlt.md'
contains stderr 'privat/stillgelegt/abschnitt/README.md: Abschnitt'
contains stderr 'privat/stillgelegt/frontmatter/README.md: Frontmatter fehlt'
contains stderr 'privat/stillgelegt/dient-unbekannt/README.md: dient enthält unbekannte Organisation „unbekannt“'
absent stderr 'WARNUNG '
contains README.md 'Testdokumentation für ASKÖ.'

echo 'Stilllegung: Alterswarnungen, Index und unveränderte Pflichtprüfungen erfolgreich geprüft.'
echo "Sortierung geprüft mit Locale ${locale_utf8:-C, also ohne Wirkung: keine en_US- oder de_DE-UTF-8-Locale gefunden}."
