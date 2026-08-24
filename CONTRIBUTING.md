# Contributing

## Local setup

```bash
cp .env.example .env
make up-demo
make smoke
```

Grafana: http://127.0.0.1:3300 (`admin` / `admin` by default).

## Making changes

1. Prefer small, focused commits.
2. Keep secrets out of the tree — only `.env.example` may contain placeholders.
3. If you change `docs/container-diagram.html`, regenerate the PDF:

```bash
make docs-pdf
```

4. Run `make smoke` before opening a PR.

## Pull requests

Describe what changed and how you tested it (`make smoke`, screenshots of
Grafana Explore if relevant). Config-only PRs are welcome.
