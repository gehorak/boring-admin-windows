# ============================================================
# boring-admin-windows - PRIMARY Makefile (Windows 11)
#
# PURPOSE
# -------
# Provide a safe, read-only discovery entrypoint into the repository.
# This Makefile routes to the public boring-admin.ps1 boundary and does not
# expose write-capable operations.
# ============================================================

SHELL := $(shell where pwsh 2>NUL || echo powershell.exe)
PSFLAGS := -NoProfile -File
ENTRYPOINT := boring-admin.ps1

.DEFAULT_GOAL := help

.PHONY: \
	help \
	info \
	check-env

help:
	@echo ""
	@echo "boring-admin-windows SAFE ENTRY (INFO / EXPLORER)"
	@echo "--------------------------------------------------"
	@echo ""
	@echo "This Makefile is a READ-ONLY entrypoint."
	@echo "Nothing here changes system state."
	@echo ""
	@echo "Available discovery commands:"
	@echo "  make help        - show public CLI help"
	@echo "  make info        - explain repository structure"
	@echo "  make check-env   - verify local tooling (read-only)"
	@echo ""
	$(SHELL) $(PSFLAGS) $(ENTRYPOINT) help

info:
	$(SHELL) $(PSFLAGS) $(ENTRYPOINT) info

check-env:
	$(SHELL) $(PSFLAGS) $(ENTRYPOINT) check env
