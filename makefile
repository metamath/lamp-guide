# Used for local processing

all: lint

lint:
	markdownlint --config .github/linters/.markdown-lint.yml \
	  docs/*.md
