# IT-Dokumentation: Tooling

Format, Prüfskript und Vorlagen für IT-Dokumentation in Markdown, gemeinsam genutzt von mehreren Dokumentations-Repositories. Enthält keine Dokumentationsinhalte.

Einbinden als Submodule unter `tooling/`:

```bash
git submodule add https://github.com/flowsworld/it-dokumentation-tooling.git tooling
```

Das `Makefile` des Dokumentations-Repositorys setzt `ORGANISATIONEN`, optional `BEKANNTE_ORGANISATIONEN` und `INDEX_BESCHREIBUNG` und ruft `bash tooling/check.sh` auf; Details im Kopf von [check.sh](check.sh). `githooks/pre-commit` prüft Commits mit gitleaks, `gitleaks.sh` die Historie in GitHub Actions.

Weiter: [Begriffe](CONTEXT.md), [Konventionen](docs/konventionen.md), [Einrichtung](docs/einrichtung.md), [Vorlagen](templates). `make test` prüft das Prüfskript.
