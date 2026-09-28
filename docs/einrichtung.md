# Arbeitsumgebung einrichten

Diese Anleitung gilt für neue und vorhandene Clones jedes Dokumentations-Repositorys. `<repository>` steht für dessen GitHub-Adresse im Format `OWNER/NAME`, `<clone>` für den lokalen Pfad, etwa `~/Code/it-dokumentation`. Zum reinen Lesen genügt die GitHub-Weboberfläche; diese Einrichtung braucht nur, wer Einträge schreibt.

Benötigt werden Bash, Git, GNU Make, [Mike Farahs yq v4](https://github.com/mikefarah/yq) und [gitleaks](https://github.com/gitleaks/gitleaks). Andere Programme namens `yq` sind nicht austauschbar. Für gitleaks die Version aus [dem CI-Skript](../gitleaks.sh) verwenden, derzeit 8.30.1.

## Windows

Die Befehle des Dokumentations-Skills laufen in **Git Bash** aus Git for Windows. Die folgenden Installationsbefehle laufen in PowerShell. Nur fehlende Werkzeuge installieren:

```powershell
winget install --id Git.Git --exact --source winget
winget install --id ezwinports.make --exact --source winget
winget install --id MikeFarah.yq --exact --source winget
winget install --id Gitleaks.Gitleaks --exact --source winget --version 8.30.1
```

Anschließend das Terminal und gegebenenfalls den Agent-Client neu öffnen, damit sie den geänderten PATH übernehmen. Git Bash lässt sich über das Startmenü öffnen. Es muss nicht als `bash` im PowerShell-PATH stehen.

Für einen Aufruf aus PowerShell den Git-Bash-Pfad einmal ermitteln:

```powershell
$gitBash = @(
    "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe"
    "$env:ProgramFiles\Git\bin\bash.exe"
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $gitBash) { throw 'Git Bash nicht gefunden. Den tatsächlichen Installationspfad in $gitBash setzen.' }
& $gitBash -lc 'cd <clone> && git status --short'
if ($LASTEXITCODE -ne 0) { throw 'Git-Bash-Aufruf fehlgeschlagen.' }
```

Bei einer benutzerdefinierten Git-Installation `$gitBash` auf deren `bin\bash.exe` setzen. Ein eventuell vorhandenes WSL-`bash.exe` gehört zu einer anderen Umgebung. `~` entspricht in Git Bash normalerweise `C:\Users\<Benutzer>`.

Ohne WinGet funktionieren auch portable yq- und gitleaks-Programme aus den offiziellen Releases. Wer diese Variante benötigt, lädt die zur Architektur passenden Dateien aus den [yq-Releases](https://github.com/mikefarah/yq/releases) und [gitleaks-Releases](https://github.com/gitleaks/gitleaks/releases), prüft die veröffentlichten SHA256-Prüfsummen und legt `yq.exe` sowie `gitleaks.exe` in einen eigenen Ordner im Benutzer-PATH. Ein gitleaks-ZIP zuerst entpacken; die yq-Datei auf `yq.exe` umbenennen.

## macOS und Linux

Unter macOS mit vorhandenem Homebrew:

```bash
brew install git bash make yq gitleaks
```

Weicht die installierte gitleaks-Version von der im CI-Skript ab, die passende macOS-Datei aus den offiziellen gitleaks-Releases verwenden. Prüfsumme prüfen, Archiv entpacken und `gitleaks` ausführbar in einem eigenen Verzeichnis vor der Homebrew-Version im PATH ablegen.

Unter Linux Bash, Git und GNU Make mit dem Paketmanager der Distribution installieren. yq v4 und die oben genannte gitleaks-Version aus den offiziellen Releases beziehen, passend zu Betriebssystem und Architektur. Prüfsummen prüfen, Archive entpacken und die Programme als `yq` und `gitleaks` ausführbar in einem Verzeichnis im PATH ablegen, beispielsweise `~/.local/bin`. Bei Distributionspaketen vorab prüfen, ob `yq` tatsächlich Mike Farahs Variante ist und gitleaks die benötigte Version bietet.

## Werkzeuge prüfen

Ab hier alle Befehle in Bash ausführen, unter Windows in Git Bash. Die Prüfung muss in derselben Umgebung laufen, die später `make check` und `git commit` ausführt:

```bash
for tool in bash git make yq gitleaks; do
  command -v "$tool" || { printf 'Fehlt im PATH: %s\n' "$tool" >&2; exit 1; }
done
bash --version
git --version
make --version
yq --version
gitleaks version
```

Erwartet werden GNU Bash, GNU Make, yq mit `github.com/mikefarah/yq` und Version `v4...` sowie die gitleaks-Version aus dem CI-Skript. Meldet `command -v` einen unerwarteten Pfad, zuerst den PATH korrigieren. Wenn Git Bash die Werkzeuge nicht findet, helfen Installationen in einer anderen Shell-Umgebung nicht.

## Clone und Hook vorbereiten

Der Zugriff auf das Dokumentations-Repository und eine Git-Commit-Identität müssen vorhanden sein. Prüfskript, Vorlagen und Hook liegen im öffentlichen [Tooling-Repository](https://github.com/flowsworld/it-dokumentation-tooling), das jedes Dokumentations-Repository als Submodule unter `tooling/` einbindet. Die Identität lässt sich mit `git var GIT_AUTHOR_IDENT` prüfen.

Nur wenn der Clone noch fehlt:

```bash
git clone --recurse-submodules https://github.com/<repository>.git <clone>
```

Anschließend auch bei einem vorhandenen Clone:

```bash
cd <clone> || exit 1
git status --short
git branch --show-current
git config --show-origin --get core.hooksPath
```

Ein leerer Status bedeutet, dass keine lokalen Änderungen vorliegen. Für den Schreibablauf des Skills muss `main` ausgecheckt sein; erst bei sauberem Arbeitsverzeichnis auf `main` mit `git pull --ff-only` aktualisieren. Bei lokalen Änderungen oder auseinander gelaufenen Historien den Zustand zunächst klären.

Nach jedem Pull das Tooling auf den Stand bringen, den das Repository festlegt. `git pull` legt neue Submodules nicht selbst an:

```bash
git submodule update --init
```

Ist kein Hook-Pfad konfiguriert, liefert der letzte Befehl keine Ausgabe und Exit 1. In diesem Fall auch den Standard-Hookordner prüfen, dessen Pfad `git rev-parse --git-path hooks` ausgibt. Dateien mit Endung `.sample` sind inaktive Beispiele; vorhandene aktive Hooks müssen bei der Einbindung erhalten bleiben.

Wenn dort keine aktiven Hooks vorliegen und kein anderer Hook-Pfad konfiguriert ist, den Repository-Hook aktivieren. Ist `.githooks` bereits konfiguriert, kann derselbe Befehl die Einstellung ausdrücklich für diesen Clone festhalten:

```bash
git config --local core.hooksPath .githooks
git config --get core.hooksPath
```

Bei einem anderen vorhandenen Hook-Pfad dessen Konfiguration erhalten und die Einbindung des Repository-Hooks klären, bevor die Einstellung geändert wird. Das gilt auch für global konfigurierte Hooks. Fertig ist die Einrichtung, wenn Commits dieses Clones `.githooks/pre-commit` ausführen und gitleaks dabei im PATH liegt. Dieser Hook ruft den gemeinsamen Hook aus `tooling/githooks/` auf; fehlt das Submodule, bricht der Commit mit einem Hinweis ab.

## Einrichtung abschließen

Im Clone ausführen:

```bash
make check
git diff -- README.md
```

Der Prüflauf muss ohne Fehler enden. Er erzeugt den Index `README.md`; dessen Änderungen gehören zum jeweiligen Dokumentationscommit. Warnungen weisen auf überfällige Verifikation hin und sind keine Installationsfehler.

Unter Windows kann derselbe Prüflauf aus PowerShell gestartet werden, nachdem `$gitBash` wie oben gesetzt wurde:

```powershell
& $gitBash -lc 'cd <clone> && make check'
if ($LASTEXITCODE -ne 0) { throw 'Dokumentenprüfung fehlgeschlagen.' }
```

`make check` prüft die Dokumente; der Pre-Commit-Hook prüft zusätzlich die gestageten Änderungen auf Geheimnisse. Beim nächsten echten Dokumentationscommit muss der Hook erfolgreich laufen. Ein synthetischer Eintrag gehört nicht auf `main`.

Die Einrichtungshinweise liegen hier zentral. Ein späteres Übergabedokument für Dritte kann diese Anleitung verlinken und sich auf Zugänge, Zuständigkeiten und Prioritäten konzentrieren.
