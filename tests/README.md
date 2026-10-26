# Tests

This directory contains the headless-first test suite. See [`docs/testing.md`](../docs/testing.md) for the test contract and [`AGENTS.md`](../AGENTS.md) for commands.

`unit/`, `integration/`, `e2e/`, `fixtures/`, `support/`, and `scenes/` hold project-owned tests and helpers. GUT covers logging, harness configuration, world configuration, and disk-scene integration; the E2E driver exercises host/client lifecycle and movement. Gravity tests are intentionally absent because gravity implementation is deferred by user direction. Regression tests belong at the lowest layer that reliably reproduces the defect, not in a separate regression folder. The boot smoke scene is not a behavior test.
