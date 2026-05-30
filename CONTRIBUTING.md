# Contributing

Thank you for contributing to EcoByte. These guidelines help maintain quality and consistency.

1. Fork the repository and create a topic branch with a descriptive name: `feature/xxx`, `fix/xxx`, or `chore/xxx`.

2. Keep changes small and focused. One logical change per branch/PR.

3. Code style and checks:

- Run `flutter format .` before committing.
- Run `dart analyze` and fix reported issues.
- Add or update unit/widget tests for behavior changes and run `flutter test`.

4. Commit messages:

- Use present-tense, imperative style, e.g. "Add product listing pagination".
- Reference issues or PRs when relevant: "Fix auth token leak (#123)".

5. Pull request checklist:

- [ ] Branch is up to date with `main` (or the target branch).
- [ ] All tests pass locally.
- [ ] Code is formatted with `flutter format`.
- [ ] Relevant documentation updated (`README.md`, `CHANGELOG.md`).

6. Updating the changelog:

- Add a brief entry to `CHANGELOG.md` under `Unreleased` or the release date.

7. CI / Quality gates:

- When CI is present, ensure the pipeline completes (analysis, tests, build).

8. Security and sensitive data:

- Never commit secrets, credentials, or keys. Use environment variables and `.env` files excluded from version control.

If you want me to open a PR or run the formatting/tests in this workspace, tell me which steps to execute and I will proceed.