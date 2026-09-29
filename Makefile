.PHONY: lint lint-md lint-yaml lint-links check-versions

lint: lint-md lint-yaml lint-links check-versions

lint-md:
	npx --yes markdownlint-cli2 "**/*.md"

lint-yaml:
	yamllint -c .yamllint.yaml .

lint-links:
	lychee --config lychee.toml "**/*.md"

check-versions:
	python3 scripts/check_versions.py versions.yaml
