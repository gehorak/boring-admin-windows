# ============================================================
# boring-admin-windows — PRIMARY Makefile (Windows 11)
#
# PURPOSE
# -------
# Provide a safe, read-only entrypoint into the repository.
# This Makefile exists to explain WHAT is available and
# HOW to proceed safely — not to execute system changes.
#
# THIS MAKEFILE DOES NOT:
# ----------------------
# - execute system-changing scripts
# - orchestrate state or workflows
# - imply authority or correctness
#
# THIS MAKEFILE EXISTS TO:
# -----------------------
# - act as an explorer / discovery interface
# - document available operational layers
# - reduce human error at first contact
#
# DESIGN PRINCIPLES
# -----------------
# - safe by default
# - explicit over implicit
# - readable in 5–10 years
#
# DEFAULT ACTION
# --------------
# Show help only.
# ============================================================

# ---------------------------------------------------------------------------
# VOCABULARY (shared, normative)  # [POLISH]
# ---------------------------------------------------------------------------
# info
#   Orientation and documentation only.
#   Does NOT execute scripts and does NOT inspect system state.
#
# audit
#   Read-only observation of system state.
#   NEVER changes system state.
#
# verify
#   Single, scoped verification of a specific area.
#
# apply
#   Baseline-changing action.
#
# overlay
#   Optional, non-baseline actions.
#
# ux
#   Explicit convenience. Never the default path.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Shell configuration
# ---------------------------------------------------------------------------

# Prefer PowerShell Core if available, fallback to Windows PowerShell.
SHELL := $(shell where pwsh 2>NUL || echo powershell.exe)

# Avoid profile side effects and policy persistence.
PSFLAGS := -NoProfile -ExecutionPolicy Bypass -File

.DEFAULT_GOAL := help

# ---------------------------------------------------------------------------
# Phony targets
# ---------------------------------------------------------------------------

.PHONY: \
	help \
	info \
	check-env

# ------------------------------------------------------------
# HELP / EXPLORER
# ------------------------------------------------------------

help:
	@echo ""
	@echo "boring-admin-windows SAFE ENTRY (INFO / EXPLORER)"
	@echo "--------------------------------------------------"
	@echo ""
	@echo "This Makefile is a READ-ONLY entrypoint."
	@echo "Nothing here changes system state."
	@echo ""
	@echo "Available discovery commands:"
	@echo "  make help        - show this overview"
	@echo "  make info        - explain repository structure"
	@echo "  make check-env   - verify local tooling (read-only)"
	@echo ""
	@echo "Operational layers (review before use):"
	@echo "  Makefile.audit        - audit / verify / recovery (read-only)"
	@echo "  Makefile.operational - apply / overlay / UX convenience"
	@echo ""
	@echo "Rule of thumb:"
	@echo "  Read first. Observe second. Act explicitly."
	@echo ""

# ------------------------------------------------------------
# REPOSITORY OVERVIEW
# ------------------------------------------------------------

info:
	@echo ""
	@echo "Repository structure overview:"
	@echo ""
	@echo "  /Makefile               -> INFO / EXPLORER (this file)"
	@echo "  /Makefile.audit         -> AUDIT / VERIFY / RECOVERY (read-only)"
	@echo "  /Makefile.operational  -> APPLY / OVERLAY / UX (writes allowed)"
	@echo ""
	@echo "Script layout:"
	@echo "  scripts/verify/*        -> observe system state"
	@echo "  scripts/apply/*         -> change baseline state"
	@echo "  scripts/overlay/*       -> optional software / UX"
	@echo "  scripts/migrate/*       -> bootstrap / one-time steps"
	@echo ""
	@echo "No desired state is stored."
	@echo "The operator remains the authority."
	@echo ""

# ------------------------------------------------------------
# ENVIRONMENT CHECK (READ-ONLY)
# ------------------------------------------------------------

check-env:
	@echo ""
	@echo "Checking PowerShell availability..."
	@pwsh -Command "& { $$PSVersionTable.PSVersion }" 2>NUL || powershell -NoProfile -Command "& { $$PSVersionTable.PSVersion }"
	@echo ""
	@echo "Checking make availability..."
	@make --version
	@echo ""
	@echo "Environment check finished."
	@echo "You may now review Makefile.audit or Makefile.operational."
	@echo ""
