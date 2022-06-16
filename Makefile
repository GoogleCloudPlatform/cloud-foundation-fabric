SHELL := /bin/bash

PRE_COMMIT_BINARY := $(shell command -v pre-commit 2>/dev/null)
AG_BINARY := $(shell command -v ag 2>/dev/null)
ENTR_BINARY := $(shell command -v entr 2>/dev/null)

PYTHON_BINARY := $(shell command -v python3 2>/dev/null)
ifndef PYTHON_BINARY
  PYTHON_BINARY := $(shell command -v python 2>/dev/null)
endif

MODULES_DIR := $(PWD)/modules
EXAMPLES_DIR := $(PWD)/examples
FAST_DIR := $(PWD)/fast
PYTHON_SRC := $(TESTS_DIR) $(TOOLS_DIR)

TESTS_DIR := $(PWD)/tests
TOOLS_DIR := $(PWD)/tools

.PHONY: init
init .git/hooks/pre-commit:
ifndef PRE_COMMIT_BINARY
	$(warning pre-commit not found.  Please install with `pip install pre-commit` or `brew install pre-commit` for code formatting and other magic.)
else
	$(PRE_COMMIT_BINARY) install
endif

.PHONY: install-dev
install-dev:
	pip install -r tools/requirements.txt

.PHONY: pre-commit
pre-commit: .git/hooks/pre-commit
	$(PRE_COMMIT_BINARY) run --all-files

.PHONY: watch
watch:
ifndef ENTR_BINARY
	$(warning entr not found. Please install entr https://eradman.com/entrproject/)
else
ifndef AG_BINARY
	$(warning ag not found.  Please install Silver Searcher https://geoff.greer.fm/ag/)
else
	ag -l --python --terraform | entr make -s pre-commit
endif
endif

.PHONY: qa
qa: lint checks test

.PHONY: lint
lint: isort black terraform-fmt

.PHONY: checks
checks: check-documentation check-boilerplate check-links check-names

.PHONY: isort
isort: $(PYTHON_SRC)
	isort $(PYTHON_SRC) --check-only

.PHONY: black
black: $(PYTHON_SRC)
	black $(PYTHON_SRC) --check

.PHONY: terraform-fmt
terraform-fmt:
	terraform fmt -recursive -check -diff $(MODULES_DIR)

.PHONY: check-documentation
check-documentation:
	$(PYTHON_BINARY) tools/check_documentation.py $(MODULES_DIR) $(EXAMPLES_DIR) $(FAST_DIR)


.PHONY: check-boilerplate
check-boilerplate:
	$(PYTHON_BINARY) tools/check_boilerplate.py $(MODULES_DIR)

.PHONY: check-links
check-links:
	$(PYTHON_BINARY) tools/check_links.py $(PWD)

.PHONY: check-names
check-names:
	$(PYTHON_BINARY) tools/check_names.py --prefix-length=10 $(FAST_DIR)/stages

.PHONY: test
test:
	pytest $(TESTS_DIR)
