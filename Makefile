SCRIPTS := \
	assume_role \
	export_credentials \
	with_assumed_role \
	with_profile

.PHONY: scripts/deps
.PHONY: scripts/gen
.PHONY: orb/validate
.PHONY: format
.PHONY: _format_shell/deps
.PHONY: format_shell/check
.PHONY: format_shell/fix
.PHONY: format_yaml/check
.PHONY: format_yaml/fix
.PHONY: lint
.PHONY: _lint_shell/deps
.PHONY: lint_shell/check

scripts/deps:
	for s in $(SCRIPTS); do sosh fetch "src/scripts/$$s.bash" || exit 1; done

scripts/gen: scripts/deps
	for s in $(SCRIPTS); do sosh pack -i "src/scripts/$$s.bash" -o "src/scripts_generated/$$s.bash" || exit 1; done

orb/validate: scripts/gen
	circleci orb pack ./src > /tmp/orb
	circleci orb validate /tmp/orb

format: format_shell/fix format_yaml/fix

_format_shell/deps: @bin/format.bash
	sosh fetch @bin/format.bash

format_shell/check: _format_shell/deps
	\@bin/format.bash check

format_shell/fix: _format_shell/deps
	\@bin/format.bash apply

format_yaml/check:
	yamlfmt --lint .

format_yaml/fix:
	yamlfmt .

lint: lint_shell/check

_lint_shell/deps: @bin/lint.bash
	sosh fetch @bin/lint.bash

lint_shell/check: _format_shell/deps _lint_shell/deps scripts/deps
	\@bin/lint.bash

check: format_shell/check format_yaml/check lint_shell/check orb/validate
