PREFIX ?= /usr
DESTDIR ?=
BINDIR ?= $(PREFIX)/bin
BASHCOMP_PATH ?= $(DESTDIR)$(PREFIX)/share/bash-completion/completions

install:
	@install -v -d "$(BASHCOMP_PATH)" && install -m 0644 -v src/completion/passit.bash-completion "$(BASHCOMP_PATH)/passit" || true
	@install -v -d "$(DESTDIR)$(BINDIR)/" && install -m 0755 -v src/passit.sh "$(DESTDIR)$(BINDIR)/passit"


uninstall:
	@rm -vrf \
		"$(DESTDIR)$(BINDIR)/passit" \
		"$(BASHCOMP_PATH)/passit" \

.PHONY: install uninstall
