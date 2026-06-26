# Contributing Guidelines

Thank you for contributing to ChessVerse AI.

## Development Philosophy

This repository must be maintained like a professional product repository, not a casual experiment.

## Branching Strategy

- `main` – stable production-ready branch
- `develop` – integration branch
- `feature/*` – feature development
- `bugfix/*` – bug fixes
- `hotfix/*` – urgent production fixes
- `release/*` – release preparation

## Commit Message Format

Use clear commit messages:

```text
docs(pvd): add executive summary
feat(auth): add JWT login
fix(game): correct knight move validation
test(ai): add Stockfish analysis tests
ci: add GitHub Actions build pipeline
```

## Pull Request Rules

- Explain what changed
- Mention testing done
- Keep PRs small
- Do not mix unrelated changes
- Do not commit secrets

## Code Quality

- Follow clean code principles
- Add tests for important logic
- Keep documentation updated
- Avoid hardcoded configuration
- Use environment variables for secrets

## Documentation Rule

Every major feature must update related documentation in `docs/`.
