SCRIPTS := \
	assume_role \
	export_credentials \
	with_assumed_role \
	with_profile

.DEFAULT_GOAL := help

# Lists every target that carries a `## ` description, in the order they appear.
# Targets without one stay out of the listing, which is how the `_` ones hide.
.PHONY: help
help:  ## Print this help
	@awk 'BEGIN{FS=":.*##"} /^[a-zA-Z0-9_\/-]+:.*##/ {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: orb/validate
orb/validate: scripts/gen  ## Pack the orb and validate it (needs a CircleCI token)
	mkdir -p dist
	circleci orb pack ./src > dist/orb.yml
	circleci orb validate dist/orb.yml

.PHONY: _format-shell/deps
_format-shell/deps:
	sosh fetch @bin/format.bash

.PHONY: _lint-shell/deps
_lint-shell/deps:
	sosh fetch @bin/lint.bash

.PHONY: scripts/deps
scripts/deps:
	for s in $(SCRIPTS); do sosh fetch "src/scripts/$$s.bash" || exit 1; done

.PHONY: scripts/gen
scripts/gen: scripts/deps  ## Pack the scripts into src/scripts_generated
	for s in $(SCRIPTS); do sosh pack -i "src/scripts/$$s.bash" -o "src/scripts_generated/$$s.bash" || exit 1; done

.PHONY: format/check
format/check: format-shell/check format-yaml/check  ## Check shell and YAML formatting

.PHONY: format/fix
format/fix: format-shell/fix format-yaml/fix  ## Format shell and YAML

.PHONY: format-shell/check
format-shell/check: _format-shell/deps  ## Check shell formatting
	./@bin/format.bash check

.PHONY: format-shell/fix
format-shell/fix: _format-shell/deps  ## Format shell scripts
	./@bin/format.bash apply

.PHONY: format-yaml/check
format-yaml/check:  ## Check YAML formatting
	yamlfmt --lint .

.PHONY: format-yaml/fix
format-yaml/fix:  ## Format YAML files
	yamlfmt .

.PHONY: lint/check
lint/check: lint-shell/check  ## Lint sources

# lint.bash runs shellcheck with --external-sources, so shellcheck follows the
# `# shellcheck source=` directives in the files it lints. Every library they
# point at has to be fetched first, or shellcheck reports SC1091 and the lint
# fails. That covers the @bin helpers and the scripts under src.
.PHONY: lint-shell/check
lint-shell/check: _format-shell/deps _lint-shell/deps scripts/deps  ## Lint shell scripts
	./@bin/lint.bash

.PHONY: check
check: format/check lint/check orb/validate  ## Run every check
