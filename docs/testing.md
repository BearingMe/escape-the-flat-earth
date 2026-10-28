# Testing

This project is headless-first. A test that needs a visible editor or manual input is supplemental; it does not replace an automated check for game logic, lifecycle, or multiplayer behavior.

## Stack

- Runtime: Godot 4.7.x and typed GDScript 2.0.
- Unit and in-process integration tests: GUT 9.7.1, vendored in `addons/gut/` and pinned to Godot 4.7.
- End-to-end tests: project-owned Godot test drivers that launch the game headlessly. No separate E2E framework is required.
- Run commands live in `AGENTS.md`.

## Test layers

- **Unit:** deterministic domain logic in isolation: world configuration, configured downward gravity, movement input bounds, acceleration/braking rules, inventory/crafting rules, damage calculations, and match-state transitions. Mock external boundaries, not the logic under test.
- **Integration:** real project scripts, Resources, scenes, autoloads, signals, save/load, and lifecycle interactions. Use real Godot objects where their behavior is part of the contract; keep tests headless.
- **End-to-end:** boot independent headless game processes and exercise player-visible flows. Multiplayer E2E must include a host and at least one separate client process, verify host-owned outcomes and replicated state, and cover orderly shutdown and disconnect paths. Do not treat two peers in one process as multiplayer E2E.
- **Regression:** not a separate test layer. When fixing a defect, add a stable reproducer at the lowest layer that catches it, then keep it permanently in that suite. Add higher-level coverage too when the defect crossed a boundary or escaped lower-level checks.

Current GUT coverage includes logging, test-harness configuration, world-config validation, camera and movement input rules, disk-scene integration, observer fall/jump/slope/wall/edge collision, and full-diameter chunk streaming bounds. The multiplayer E2E runner verifies six total peers, standard-gravity grounding, host-owned observer movement with 100 ms delayed intents, client position convergence, disconnect cleanup, teardown, and two-peer distant region streaming (`--e2e-distant-exploration`). `tests/scenes/world_profile.tscn` profiles chunk generation, streaming load budgets, memory cleanup, and runtime performance counters. `tests/scenes/boot_smoke.tscn` only verifies that a minimal runtime scene and autoloads start headlessly; it is a boot smoke check, not behavior coverage.

## Repository layout

```text
tests/
  unit/          # Fast, deterministic GUT tests; mirror owned source features
  integration/   # Real scenes, autoloads, resources, and subsystem interactions
  e2e/           # Headless scenario drivers and multi-process host/client checks
  fixtures/      # Small deterministic test data only
  support/       # Shared test helpers; keep these smaller than the production API
```

GUT discovers `test_*.gd` scripts in `unit/` and `integration/` using `.gutconfig.json`. `tests/run_gut.gd` checks for test files before invoking GUT and also treats GUT's otherwise-successful empty-run response as failure. E2E driver scripts are deliberately outside GUT discovery; the runner must report a nonzero exit on assertion failure, process failure, or timeout.

## GUT conventions

- Test scripts extend `GutTest`; test functions start with `test_` and contain assertions. Use `before_each`/`after_each` for per-test setup and cleanup.
- Give each test one behavior and a name that describes the condition and expected result.
- Free created Nodes and Objects with GUT's `autofree`, `autoqfree`, or `add_child_auto*` helpers. Leaked nodes are test failures to investigate, not noise to suppress.
- Prefer GUT's signal and frame wait helpers to arbitrary delays. Bound waits with timeouts and assert that the awaited event actually occurred. Wait for physics frames when asserting physics results.
- Use fixed random seeds and explicit test inputs. Compare floating-point physics values with tolerances; avoid fragile exact-frame or whole-world snapshot assertions.
- Mock clocks, external services, and nondeterministic boundaries only when needed. Do not mock host-authoritative rules or engine behavior that the test is intended to verify.
- GUT is configured to fail on unexpected engine, GUT, and `push_error` errors. Tests for an expected error must explicitly assert the error and its user-visible/recovery behavior; never disable error tracking for an entire suite to make it pass.
- For expected logged errors, call the operation first and then use GUT's matching `assert_engine_error()` or `assert_push_error()`; the assertion consumes the tracked error. Also assert the operation's returned failure and recovery/state behavior.
- `Log.error()` emits through `push_error()` and therefore fails GUT unless explicitly asserted. Follow [`docs/logging.md`](logging.md); do not mute the logger/error tracker to make a test pass.

## Headless E2E requirements

Each scenario should declare its seed, role/process topology, success condition, and timeout. The runner should:

1. Start host and client as independent Godot processes with headless display/audio, isolated test data, and unique logs.
2. Use bounded readiness/ completion signals or result files rather than fixed sleeps. Bound every wait and fail with diagnostics on timeout.
3. Assert externally observable outcomes: match started, expected authoritative state, client convergence, and expected result after disconnect or rejected input.
4. Capture each process's exit code and logs; a clean engine exit alone is not a passing scenario.
5. Stop every child process and clean temporary data on both success and failure.

The first E2E scenarios should cover the core loop as it becomes available: join/spawn, a representative loot or interaction action, host-resolved combat/state change, escape or match-end resolution, and disconnect/recovery. Malformed or unauthorized client requests must be rejected without changing canonical state.

## Coverage and quality bar

Do not set a line-coverage percentage until a compatible coverage tool is selected and enforced. Instead, for each changed behavior, cover its normal outcome, meaningful boundary/invalid inputs, relevant authority checks, and failure/recovery path. Every fallible operation must have tests for the error contract and for absence of partial state changes. Every bug fix gets a regression test unless the behavior cannot be automated; document any such exception in its milestone checkpoint.

Do not test trivial getters, constants, engine internals, or the same assertion at every layer. A passing test count is not a coverage argument.

## Flakiness and test data

- Tests are deterministic and isolated: no public servers, personal save data, secrets, or machine-specific paths.
- A flaky test is a defect. Do not hide it with automatic retries or leave it quarantined indefinitely. If temporary quarantine is unavoidable, link an issue, name an owner, and set a removal condition.
- Test fixtures are minimal, committed, and safe to regenerate. Use temporary locations for writes and clean them up even on failure.

## References

- [Godot 4.7 command-line tutorial](https://docs.godotengine.org/en/4.7/tutorials/editor/command_line_tutorial.html)
- [GUT 9.7.1 command line](https://gut.readthedocs.io/en/v9.7.1/Command-Line.html)
- [GUT 9.7.1 creating tests](https://gut.readthedocs.io/en/v9.7.1/Creating-Tests.html)
- [GUT 9.7.1 quick start](https://gut.readthedocs.io/en/v9.7.1/Quick-Start.html)
- [Godot 4.7 logging](https://docs.godotengine.org/en/4.7/tutorials/scripting/logging.html)
