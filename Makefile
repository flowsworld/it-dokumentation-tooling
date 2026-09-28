# Prüft das Tooling selbst. Dokumentations-Repositories rufen check.sh über ihr eigenes Makefile auf.
.PHONY: test
test:
	@bash tests/check-stilllegung.sh
