# Konventionen für Einträge und Systemblätter

Diese Regeln gelten in jedem Dokumentations-Repository. Begriffe stehen in [CONTEXT.md](../CONTEXT.md), Vorlagen in [templates/](../templates), die Prüfregeln setzt `make check` durch.

- Pfad: `<organisation>/<system>/<eintrag>/README.md`. Die Organisation richtet sich nach dem Eigentümer des Systems, nie nach dem Nutznießer. Jede Organisation hat ihr eigenes Dokumentations-Repository; ein Eintrag liegt immer in dem seiner Organisation. Wem ein Eintrag außerdem dient, steht in der Frontmatter unter `dient`.
- Systeme heißen nach ihrer Rolle (`webserver`, `laptop`, `website`), nicht nach Hostname oder Domain. Die stehen im Systemblatt. Jeder Systemordner hat ein Systemblatt `README.md`.
- Eintragsordner: Kleinbuchstaben, Bindestriche, ASCII, Substantive, ohne Präfix, das der Systemordner schon sagt (`backup`, nicht `webserver-backup`). Produktnamen englisch, Beschreibungen deutsch. Der Titel im Eintrag bleibt voll und deutsch.
- Querverweise innerhalb eines Repositorys als relative Markdown-Links.
- Verweise in ein anderes Dokumentations-Repository als absolute GitHub-URL auf `main`. Die Abhängigkeit zusätzlich im Text so beschreiben, dass sie ohne Zugriff auf das andere Repository verständlich ist: welches System, wem es gehört, wofür es gebraucht wird. Wer ein Repository lesen darf, hat nicht unbedingt Zugriff auf die anderen.
- Braucht eine Organisation ein System aus einem anderen Repository, führt ihr `docs/uebernahme.md` es im Abschnitt zu Abhängigkeiten mit Zweck und Verweis nach der vorigen Regel. Neue oder entfallene Abhängigkeiten dort nachtragen.
- Nach verifizierter endgültiger Abschaltung das Systemblatt auf `Deaktiviert` setzen; Systemblatt und Einträge bleiben am bisherigen Ort. Ein Ersatz in derselben Rolle wird im bestehenden Systemblatt und einem Eintrag zum Wechsel dokumentiert.
- Einträge stillgelegter Systeme gelten als historisch, ihre Statuswerte bleiben erhalten. Für sie sowie Dokumente mit `Deaktiviert` oder `Veraltet` entfallen Alterswarnungen; Format- und Linkprüfungen bleiben aktiv.
- `README.md` im Root ist der generierte Index. Nach jeder Änderung `make check` ausführen und den Index mit committen.
