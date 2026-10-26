# Tests

This directory is scaffolded for a headless-first test suite. See [`docs/testing.md`](../docs/testing.md) for the test contract and [`AGENTS.md`](../AGENTS.md) for commands.

`unit/`, `integration/`, `e2e/`, `fixtures/`, `support/`, and `scenes/` are reserved for project-owned tests and helpers. The initial unit suite protects the harness configuration; it is not gameplay coverage. Do not add empty passing tests: add real tests alongside the gameplay systems they exercise. Regression tests belong at the lowest layer that reliably reproduces the defect, not in a separate regression folder. The boot smoke scene is not a behavior test.
