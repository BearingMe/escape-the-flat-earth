# Error Handling

Error handling is part of each feature's contract. Recoverable failures must not crash a match, silently corrupt canonical state, or disappear into logs that nobody sees.

## Classify failures

- **Expected/recoverable:** invalid player input, unavailable peer, rejected network intent, missing optional content, or an operation that can be retried. Return a typed `Error`/domain result or emit a typed failure signal. Let the caller choose the recovery and player feedback.
- **Unexpected operational failure:** required resource or persistence/network operation failed unexpectedly. Preserve the original error, attach operation context, stop the affected operation safely, and report it once at the boundary that can decide recovery.
- **Programmer invariant violation:** impossible internal state or broken assumptions. Use `assert` for development-time invariants and make the failure visible; do not use assertions as validation for user or network input.

GDScript does not use exceptions as normal control flow. Check `Error` return values immediately and propagate them or translate them into a domain-specific result. Do not return a plausible success value after failure, or use an ambiguous sentinel when that value could be valid.

## Boundaries and state safety

- Validate files, serialized data, Resources, scene assumptions, and all RPC/client intents at the boundary before using them.
- Validate before mutating shared state. Failed operations must leave canonical state unchanged or roll back explicitly.
- The host is the authority for match state, damage, loot, physics outcomes, and win conditions. Reject malformed or unauthorized client intents without trusting client-reported outcomes.
- Give asynchronous and network operations a timeout, cancellation/teardown path, and explicit completion/failure result. A disconnected peer must not leave a match-critical await or resource alive indefinitely.
- Make cleanup idempotent. On failure, close files, disconnect signals, free temporary Nodes, and stop spawned processes without masking the original error.

## Reporting

- Return/emit expected failures; do not use `push_error()` for ordinary invalid input or normal disconnects.
- Use `push_warning()` for a recoverable fallback that is useful to diagnose, not for routine control flow. Avoid repeating the same warning every frame or for every packet.
- Use `push_error()` once for an unexpected failure that cannot be handled locally. Include the operation and relevant safe context (such as resource path, subsystem, peer ID, or request ID) so a headless log is actionable.
- Log at the layer that owns the recovery decision. Lower layers should return context-bearing failure information instead of logging and then causing every caller to log the same error again.
- Never log credentials, private configuration, or full untrusted payloads. Do not use `print()` for error reporting.

## Tests required for fallible paths

For every public or cross-system operation that can fail, test:

1. Success produces the documented result and state change.
2. Expected failure returns/emits the right category and does not mutate canonical state.
3. Malformed/untrusted inputs are rejected safely at the boundary.
4. Cleanup/retry/disconnect behavior is bounded and idempotent where applicable.
5. Unexpected engine/GUT/`push_error` output fails the headless suite. If an error is intentional, assert it explicitly and also assert the recovery behavior.

See [Testing](testing.md) for test layers and conventions.
