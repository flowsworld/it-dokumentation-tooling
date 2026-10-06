#!/usr/bin/env bash
# Prüft alle Einträge und Systemblätter gegen Frontmatter-Schema, Pflichtabschnitte
# und Links, warnt bei überfälligem Prüfdatum und erzeugt den Index (README.md im Root).
#
# Liegt als Submodule unter tooling/ im Dokumentations-Repository und prüft dessen Root.
# Aufruf: make check. Das Makefile des Repositorys setzt die Konfiguration:
#   ORGANISATIONEN           Organisationsordner in diesem Repository (Pflicht)
#   BEKANNTE_ORGANISATIONEN  zulässige Werte für dient (Standard: ORGANISATIONEN)
#   INDEX_BESCHREIBUNG       erster Satz des Index (Pflicht)
# Exit 1 bei mindestens einem Fehler. Warnungen brechen nicht ab, sie landen im Index.
# Läuft mit Bash 3.2 (macOS) und GNU Bash; braucht yq (https://github.com/mikefarah/yq).

# Die Meldungen verwenden absichtlich deutsche Anführungszeichen.
# shellcheck disable=SC1111

set -euo pipefail
cd "$(dirname "$0")/.."

: "${ORGANISATIONEN:?ORGANISATIONEN fehlt; im Makefile des Repositorys setzen}"
: "${INDEX_BESCHREIBUNG:?INDEX_BESCHREIBUNG fehlt; im Makefile des Repositorys setzen}"

# Native Windows-Builds von make (etwa ezwinports) reichen Werte über die ANSI-Codepage weiter
# und machen aus „Ö“ „Ã–“. Ein so verfälschter Wert ergibt, zurück nach CP1252 kodiert, wieder
# gültiges UTF-8; ein korrekter Wert mit Umlauten nicht und bleibt deshalb unverändert.
if repariert=$(printf '%s' "$INDEX_BESCHREIBUNG" | iconv -f UTF-8 -t CP1252 2>/dev/null) &&
   printf '%s' "$repariert" | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1; then
  INDEX_BESCHREIBUNG="$repariert"
fi

# Byteweise sortieren, damit der Index auf jedem Rechner gleich aussieht, unabhängig von der Locale.
sort() { LC_ALL=C command sort "$@"; }
BEKANNTE_ORGANISATIONEN="${BEKANNTE_ORGANISATIONEN:-$ORGANISATIONEN}"
TOOLING_URL="https://github.com/flowsworld/it-dokumentation-tooling/blob/main"
STATUS_WERTE="Aktiv und verifiziert|Teilweise aktiv|Blockiert|Deaktiviert|Veraltet"
FRIST_MONATE_STANDARD=12
FRIST_MONATE_KURZ=3            # für Teilweise aktiv und Blockiert
INDEX="README.md"

H2_EINTRAG="Eckdaten|Zweck|Voraussetzungen|Umgesetzte Änderungen|Betriebsablauf|Verifikation|Fehlerbehebung|Rückbau|Sicherheits- und Datenschutzhinweise|Änderungsverlauf"
H3_EINTRAG="Geprüft|Nicht geprüft"
H2_SYSTEMBLATT="Eckdaten|Zugang|Hinweise|Änderungsverlauf"

command -v yq >/dev/null || { echo "yq fehlt im PATH. Einrichtung: tooling/docs/einrichtung.md (Mike Farah yq v4)" >&2; exit 2; }

fehler=0
warnungen=$(mktemp)
zeilen=$(mktemp)      # TSV: org, system, art, pfad, titel, status, pruefdatum, dient, tags
trap 'rm -f "$warnungen" "$zeilen"' EXIT

fehler() { echo "FEHLER   $1: $2" >&2; fehler=$((fehler + 1)); }
warnung() { echo "WARNUNG  $1: $2" >&2; printf '%s\t%s\n' "$1" "$2" >>"$warnungen"; }

# Datum YYYY-MM-DD validieren; funktioniert mit GNU und BSD date.
datum_gueltig() {
  [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] || return 1
  if date --version >/dev/null 2>&1; then
    [ "$(date -d "$1" +%F 2>/dev/null)" = "$1" ]
  else
    [ "$(date -j -f %Y-%m-%d "$1" +%F 2>/dev/null)" = "$1" ]
  fi
}

# Heutiges Datum minus N Monate als YYYY-MM-DD.
frist_datum() {
  if date --version >/dev/null 2>&1; then
    date -d "-$1 months" +%F
  else
    date -v-"$1"m +%F
  fi
}

# Alle Zeilen der Frontmatter ohne die Trenner; leer, wenn keine vorhanden.
frontmatter() {
  awk 'NR == 1 { if ($0 != "---") exit 1; next } $0 == "---" { exit } { print }' "$1"
}

# Dateiinhalt ohne eingezäunte Codeblöcke, damit Kommentare darin nicht als Überschrift zählen.
ohne_codebloecke() { awk '/^```/ { drin = !drin; next } !drin' "$1"; }

# Erste Überschrift ersten Grades ohne das Rautezeichen.
titel_aus_h1() { awk '/^```/ { drin = !drin; next } !drin && /^# / { sub(/^# +/, ""); print; exit }' "$1"; }

# Prüft, dass jede Überschrift der Liste (mit | getrennt) genau einmal vorkommt.
pruefe_ueberschriften() {
  local datei="$1" ebene="$2" liste="$3" name anzahl
  local IFS='|'
  for name in $liste; do
    anzahl=$(ohne_codebloecke "$datei" | grep -c -E "^${ebene} ${name}\$" || true)
    [ "$anzahl" -eq 1 ] || fehler "$datei" "Abschnitt „${ebene} ${name}“ muss genau einmal vorkommen, gefunden: $anzahl"
  done
}

# Relative Markdown-Links müssen auf existierende Dateien zeigen.
pruefe_links() {
  local datei="$1" verzeichnis ziel
  verzeichnis=$(dirname "$datei")
  while IFS= read -r ziel; do
    case "$ziel" in http://*|https://*|mailto:*|tel:*|'#'*) continue ;; esac
    ziel="${ziel%%#*}"
    [ -n "$ziel" ] || continue
    [ -e "$verzeichnis/$ziel" ] || fehler "$datei" "Link zeigt ins Leere: $ziel"
  done < <(grep -oE '\]\([^)]+\)' "$datei" | sed -E 's/^\]\((.*)\)$/\1/; s/ .*$//' || true)
}

pruefe_datei() {
  local datei="$1" art="$2" org="$3" system="$4" systemstatus="${5:-}"
  local fm organisation_fm system_fm status pruefdatum nachfolger dient tags typ frist titel

  fm=$(frontmatter "$datei") || { fehler "$datei" "Frontmatter fehlt (Datei muss mit --- beginnen)"; return; }
  printf '%s\n' "$fm" | yq -e '.' >/dev/null 2>&1 || { fehler "$datei" "Frontmatter ist kein gültiges YAML"; return; }

  organisation_fm=$(printf '%s\n' "$fm" | yq -r '.organisation // ""')
  system_fm=$(printf '%s\n' "$fm" | yq -r '.system // ""')
  status=$(printf '%s\n' "$fm" | yq -r '.status // ""')
  pruefdatum=$(printf '%s\n' "$fm" | yq -r '.pruefdatum // ""')
  nachfolger=$(printf '%s\n' "$fm" | yq -r '.nachfolger // ""')

  [ "$organisation_fm" = "$org" ] || fehler "$datei" "organisation „${organisation_fm}“ passt nicht zum Pfad „${org}“"
  [ "$system_fm" = "$system" ] || fehler "$datei" "system „${system_fm}“ passt nicht zum Pfad „${system}“"
  [[ "$status" =~ ^(${STATUS_WERTE})$ ]] || fehler "$datei" "status „${status}“ ist keiner von: ${STATUS_WERTE//|/, }"
  datum_gueltig "$pruefdatum" || fehler "$datei" "pruefdatum „${pruefdatum}“ ist kein gültiges Datum YYYY-MM-DD"

  if [ "$status" = "Veraltet" ]; then
    if [ -z "$nachfolger" ]; then
      fehler "$datei" "Status Veraltet braucht das Feld nachfolger"
    elif [ ! -f "$nachfolger/README.md" ]; then
      fehler "$datei" "nachfolger „${nachfolger}“ existiert nicht"
    fi
  elif [ -n "$nachfolger" ]; then
    fehler "$datei" "nachfolger ist nur bei Status Veraltet erlaubt"
  fi

  typ=$(printf '%s\n' "$fm" | yq -r '.dient | type')
  case "$typ" in
    '!!null') dient="" ;;
    '!!seq')
      [ "$art" = "Eintrag" ] || fehler "$datei" "dient ist nur bei Einträgen erlaubt"
      dient=$(printf '%s\n' "$fm" | yq -r '.dient | join(", ")')
      for o in $(printf '%s\n' "$fm" | yq -r '.dient[]'); do
        [[ " $BEKANNTE_ORGANISATIONEN " == *" $o "* ]] || fehler "$datei" "dient enthält unbekannte Organisation „${o}“"
      done ;;
    *) fehler "$datei" "dient muss eine Liste sein"; dient="" ;;
  esac

  typ=$(printf '%s\n' "$fm" | yq -r '.tags | type')
  case "$typ" in
    '!!null') tags="" ;;
    '!!seq')
      tags=$(printf '%s\n' "$fm" | yq -r '.tags | join(", ")')
      for t in $(printf '%s\n' "$fm" | yq -r '.tags[]'); do
        [[ "$t" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || fehler "$datei" "Tag „${t}“ ist nicht kebab-case ASCII"
        if [ "$t" = "$org" ] || [ "$t" = "$system" ]; then
          fehler "$datei" "Tag „${t}“ wiederholt Organisation oder System"
        fi
      done ;;
    *) fehler "$datei" "tags muss eine Liste sein"; tags="" ;;
  esac

  [ "$(ohne_codebloecke "$datei" | grep -c -E '^# ' || true)" -eq 1 ] || fehler "$datei" "genau eine Überschrift „# Titel“ erwartet"
  titel=$(titel_aus_h1 "$datei")
  if [ "$art" = "Eintrag" ]; then
    pruefe_ueberschriften "$datei" '##' "$H2_EINTRAG"
    pruefe_ueberschriften "$datei" '###' "$H3_EINTRAG"
    awk '/^# /{gefunden=1; next} gefunden && NF {print; exit}' "$datei" | grep -q '^> \*\*Änderung:\*\*' ||
      fehler "$datei" "Kurzbeschreibung „> **Änderung:** …“ muss direkt nach dem Titel stehen"
  else
    pruefe_ueberschriften "$datei" '##' "$H2_SYSTEMBLATT"
  fi
  pruefe_links "$datei"

  # Historische Dokumente bleiben validiert, brauchen aber keine erneute Betriebsprüfung.
  if [ "$systemstatus" != "Deaktiviert" ] && [ "$status" != "Deaktiviert" ] &&
     [ "$status" != "Veraltet" ] && datum_gueltig "$pruefdatum"; then
    case "$status" in
      "Teilweise aktiv"|"Blockiert") frist=$FRIST_MONATE_KURZ ;;
      *) frist=$FRIST_MONATE_STANDARD ;;
    esac
    [[ "$pruefdatum" > "$(frist_datum "$frist")" ]] || warnung "$datei" "Prüfdatum $pruefdatum ist älter als $frist Monate"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$org" "$system" "$art" "$datei" "$titel" "$status" "$pruefdatum" "$dient" "$tags" >>"$zeilen"
}

# Alle Systeme und Einträge einsammeln.
for org in $ORGANISATIONEN; do
  [ -d "$org" ] || continue
  for systemdir in "$org"/*/; do
    [ -d "$systemdir" ] || continue
    systemdir="${systemdir%/}"
    system=$(basename "$systemdir")
    systemstatus=""
    if [ -f "$systemdir/README.md" ]; then
      pruefe_datei "$systemdir/README.md" "Systemblatt" "$org" "$system"
      systemstatus=$(awk -F'\t' -v org="$org" -v s="$system" \
        '$1 == org && $2 == s && $3 == "Systemblatt" { print $6 }' "$zeilen")
    else
      fehler "$systemdir" "Systemblatt README.md fehlt"
    fi
    for eintragdir in "$systemdir"/*/; do
      [ -d "$eintragdir" ] || continue
      eintragdir="${eintragdir%/}"
      if [ -f "$eintragdir/README.md" ]; then
        pruefe_datei "$eintragdir/README.md" "Eintrag" "$org" "$system" "$systemstatus"
      else
        fehler "$eintragdir" "Eintrag ohne README.md"
      fi
    done
  done
done

# Index erzeugen.
{
  echo "# IT-Dokumentation"
  echo
  echo "$INDEX_BESCHREIBUNG"
  [ ! -f docs/uebernahme.md ] || echo "Neu hier oder mit der Übernahme betraut? [Hier beginnen](docs/uebernahme.md)."
  echo "Dieser Index wird von \`make check\` aus der Frontmatter erzeugt. Nicht von Hand bearbeiten."
  echo
  # Links ins Tooling zeigen auf GitHub, weil die Weboberfläche Dateien in Submodules nicht öffnet.
  echo "Begriffe: [CONTEXT.md]($TOOLING_URL/CONTEXT.md). Vorlagen: [Eintrag]($TOOLING_URL/templates/eintrag.md), [Systemblatt]($TOOLING_URL/templates/systemblatt.md)."
  echo "Einrichtung für Windows, macOS und Linux: [Arbeitsumgebung einrichten]($TOOLING_URL/docs/einrichtung.md)."

  for org in $ORGANISATIONEN; do
    grep -q "^${org}	" "$zeilen" || continue
    echo
    echo "## $org"
    for gruppe in laufend stillgelegt; do
      systeme=$(awk -F'\t' -v org="$org" -v gruppe="$gruppe" \
        '$1 == org && $3 == "Systemblatt" && (($6 == "Deaktiviert") == (gruppe == "stillgelegt")) { print $2 }' "$zeilen" | sort)
      [ -n "$systeme" ] || continue
      ebene='###'
      status_spalte='Status'
      if [ "$gruppe" = "stillgelegt" ]; then
        ebene='####'
        status_spalte='Damaliger Status'
        echo
        echo "### Stillgelegte Systeme"
        echo
        echo "Die folgenden Einträge dokumentieren den damaligen Stand. Ihre Statuswerte beschreiben keinen heutigen Betrieb."
      fi
      printf '%s\n' "$systeme" |
      while IFS= read -r system; do
        sb=$(awk -F'\t' -v org="$org" -v s="$system" '$1 == org && $2 == s && $3 == "Systemblatt"' "$zeilen")
        echo
        printf '%s [%s](%s)\n\n' "$ebene" "$(printf '%s' "$sb" | cut -f5)" "$(printf '%s' "$sb" | cut -f4)"
        printf 'Status: %s. Geprüft: %s.\n' "$(printf '%s' "$sb" | cut -f6)" "$(printf '%s' "$sb" | cut -f7)"
        if awk -F'\t' -v org="$org" -v s="$system" '$1 == org && $2 == s && $3 == "Eintrag"' "$zeilen" | grep -q .; then
          echo
          echo "| Eintrag | $status_spalte | Geprüft | Dient | Tags |"
          echo "|---|---|---|---|---|"
          awk -F'\t' -v org="$org" -v s="$system" '$1 == org && $2 == s && $3 == "Eintrag" { printf "| [%s](%s) | %s | %s | %s | %s |\n", $5, $4, $6, $7, $8, $9 }' "$zeilen" | sort
        fi
      done
    done
  done

  echo
  echo "## Warnungen"
  echo
  if [ -s "$warnungen" ]; then
    awk -F'\t' '{ printf "- [%s](%s): %s\n", $1, $1, $2 }' "$warnungen"
  else
    echo "Keine."
  fi

  echo
  echo "## Tags"
  echo
  alle_tags=$(cut -f9 "$zeilen" | tr ',' '\n' | sed 's/^ *//; s/ *$//' | grep -v '^$' | sort | uniq -c | sort -k2 | awk '{ printf "`%s` (%s), ", $2, $1 }' | sed 's/, $//' || true)
  echo "${alle_tags:-Keine.}"
} >"$INDEX"

anzahl=$(wc -l <"$zeilen" | tr -d ' ')
echo "Geprüft: $anzahl Dateien, Fehler: $fehler, Warnungen: $(wc -l <"$warnungen" | tr -d ' '). Index: $INDEX" >&2
[ "$fehler" -eq 0 ]
