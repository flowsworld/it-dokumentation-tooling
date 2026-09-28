# IT-Dokumentation

Verifizierte IT-Dokumentation liegt in einem Dokumentations-Repository je Organisation. Dieses Tooling-Repository enthält Format, Prüfskript und Vorlagen, die alle Dokumentations-Repositories gemeinsam nutzen.

## Language

**Organisation**:
Die Partei, der ein System gehört oder der ein Eintrag dient, als Kürzel in Kleinbuchstaben, etwa `privat` oder `verein`. Oberste Ordnerebene. Jede Organisation hat ihr eigenes Dokumentations-Repository; die zulässigen Werte legt dessen `Makefile` fest.
_Avoid_: Mandant, Kunde, Bereich

**Dokumentations-Repository**:
Das Git-Repository mit den Systemen und Einträgen einer Organisation. Bindet dieses Tooling als Submodule unter `tooling/` ein.
_Avoid_: Doku-Repo, Mandanten-Repo

**System**:
Ein Rechner, Gerät, Dienstkonto oder Produkt, an dem Änderungen dokumentiert werden. Liegt im Ordner der Organisation, die es besitzt, und heißt nach seiner Rolle, nicht nach Hostname oder Domain; ein Ersatz in derselben Rolle führt das bestehende System fort. Zweite Ordnerebene.
_Avoid_: Computername, Host, Maschine

**Stillgelegtes System**:
Ein dauerhaft außer Betrieb genommenes System mit Status `Deaktiviert`. Seine Einträge beschreiben den damaligen Stand; ihre gespeicherten Statuswerte bleiben erhalten.
_Avoid_: Archivsystem, gelöschtes System

**Systemblatt**:
Das handgepflegte `README.md` eines Systems: was es ist, wo es steht, wem es gehört, wie man es erreicht.
_Avoid_: Inventareintrag, Übersicht

**Eintrag**:
Eine dokumentierte, verifizierte, dauerhafte Änderung an einem System. Ein Ordner mit genau einer `README.md`, dritte Ordnerebene. Liegt immer unter seinem System; welchen Organisationen die Änderung dient, sagt die Frontmatter.
_Avoid_: Doku, Änderungs-README, Funktion

**Frontmatter**:
Der YAML-Block am Anfang eines Eintrags oder Systemblatts mit Organisation, System, Status, Prüfdatum und optional Tags, Nutznießern und Nachfolger. Einzige maschinenlesbare Quelle für Index und Prüfung.
_Avoid_: Metadaten-Datei, Header

**Tag**:
Ein Schlagwort in der Frontmatter, das Zuordnungen ausdrückt, die die Ordnerstruktur nicht abbildet, etwa eine mitnutzende Organisation oder einen Kunden.
_Avoid_: Label, Kategorie

**Status**:
Der dokumentierte Betriebszustand eines Eintrags oder Systemblatts: `Aktiv und verifiziert`, `Teilweise aktiv`, `Blockiert`, `Deaktiviert` oder `Veraltet`. Bei Einträgen eines stillgelegten Systems bezeichnet er den damaligen Stand.
_Avoid_: Zustand, State

**Prüfdatum**:
Der Tag der letzten realen Verifikation eines Eintrags oder Systemblatts, als `YYYY-MM-DD`. Nicht das Datum der letzten Textänderung.
_Avoid_: Stand, Aktualisiert am, Zeitstempel

**Nutznießer**:
Die Organisationen, denen ein Eintrag dient, in der Frontmatter als `dient`. Fehlt das Feld, dient der Eintrag nur der Organisation, der das System gehört.
_Avoid_: Mandant, Kunde, Empfänger

**Nachfolger**:
Der Eintrag, der einen veralteten Eintrag ersetzt. Pflicht bei Status `Veraltet`, sonst nicht erlaubt.
_Avoid_: Ersatz, neue Version

**Eckdaten**:
Die Tabelle am Anfang eines Eintrags oder Systemblatts mit den fachlichen Kenndaten, etwa Dienstkontext, zentraler Funktion, Hostname oder Konto-ID. Enthält nichts, was schon in der Frontmatter steht.
_Avoid_: Status-Tabelle, Steckbrief, Metadaten

**Index**:
Die vom Prüfskript aus der Frontmatter erzeugte Übersicht aller Einträge im Root eines Dokumentations-Repositorys.
_Avoid_: Inventar, Inhaltsverzeichnis

**Prüfskript**:
Das Bash-Skript `check.sh` dieses Tooling-Repositorys. Läuft über `make check` im Dokumentations-Repository, validiert Frontmatter, Pflichtabschnitte und Prüfdatum und erzeugt den Index.
_Avoid_: Linter, Validator
