---
organisation: <organisation>
system: <rollenname-des-systems>
status: <Aktiv und verifiziert | Teilweise aktiv | Blockiert | Deaktiviert | Veraltet>
pruefdatum: <YYYY-MM-DD>
# dient: [<organisation>, <organisation>]   nur, wenn der Eintrag mehr als der Pfad-Organisation dient
# tags: [<tag>, <tag>]                       nur, was Pfad und Frontmatter nicht ausdrücken
# nachfolger: <organisation>/<system>/<eintrag>   nur bei Status Veraltet
---

# <Kurze Bezeichnung der Änderung>

> **Änderung:** <Ein bis drei Sätze: Was wurde geändert, wie arbeitet die Lösung, ist der Zustand aktiv und verifiziert oder welche Einschränkung besteht.>

## Eckdaten

| Merkmal | Wert |
|---|---|
| Dienstkontext | <Benutzer, Dienst oder Prozess, in dem die Änderung wirkt> |
| Zentrale Funktion | <Was die Änderung leistet, in einem Halbsatz> |
| Zentrale Dateien | <Pfade, die die Änderung tragen> |

<Verweise auf andere Systeme oder Einträge immer als relative Links: [Titel](../../../organisation/system/README.md).>

## Zweck

<Warum die Änderung nötig war und welches Problem sie löst.>

## Voraussetzungen

<Nach Bedarf gegliedert: System und Architektur, Software und Versionen, Berechtigungen, externe Abhängigkeiten, Zugang und Konfiguration. Keine Secrets, nur deren Ablageort.>

## Umgesetzte Änderungen

<Alle dauerhaft geänderten Artefakte: Konfigurationsdateien, Dienste, Skripte, Verzeichnisse, Rechte, sicherheitsrelevante Entscheidungen. Nur die final verwendete Lösung.>

## Betriebsablauf

<Startreihenfolge, Verhalten bei Neustart, Logs, sichere Statusbefehle, kontrolliertes Stoppen und Starten. Befehle geben keine Secrets aus und sind nicht destruktiv.>

## Verifikation

### Geprüft

<Nur Tatsachen aus realen Tool-Ausgaben, mit Datum.>

### Nicht geprüft

<Ausgelassene Schreib- und Löschtests, nicht getesteter Neustart, ungeprüfte Fehlerfälle und externe Abhängigkeiten.>

## Fehlerbehebung

<Bekannte, konkrete Fehlerbilder mit Symptom, Ursache und Maßnahme.>

## Rückbau

<Sichere Reihenfolge: Nutzung beenden, Dienste stoppen, Verbindungen lösen, Artefakte entfernen, gemeinsam genutzte Komponenten ausdrücklich erhalten. Aktionen mit Außenwirkung brauchen eine ausdrückliche Bestätigung.>

## Sicherheits- und Datenschutzhinweise

<Was der Eintrag bewusst nicht enthält, welche Risiken bleiben, was beim Umgang mit Zugängen zu beachten ist.>

## Änderungsverlauf

| Datum | Änderung |
|---|---|
| <YYYY-MM-DD> | <Sachliche Änderung in einem Satz.> |
