# moon_wesl vs wesl-rs Parity Tracker

Last updated: 2026-04-15

Baseline target for parity planning: `wesl` 0.3.2 and `wesl-cli` 0.3.1
public surfaces as reviewed on docs.rs on 2026-04-15. This tracker focuses on
closing the largest product and architecture gaps from the current
`moon_wesl` implementation.

## Status Legend

- `TODO`: not started
- `IN_PROGRESS`: currently being fixed
- `BLOCKED`: blocked by platform/public API limitations or external dependency constraints
- `DONE`: fixed and verified locally

## Issues

| ID | Source | Problem | Status | Notes |
| --- | --- | --- | --- | --- |
| PARITY-001 | `wesl::Wesl`, `wgsl-parse`, local `compile.mbt` | Replace the current text-oriented compiler core with an AST-backed pipeline. | `IN_PROGRESS` | Phase 1. `moon_wesl` currently splits items, scans identifiers, and rewrites strings directly. That is enough for a small subset, but it is the main blocker for spec coverage, precise lowering, and reliable diagnostics. Current slice landed: explicit internal `TopLevelItem` and `ModuleItemKind` nodes, top-level module parsing now goes through those nodes before building import/name/reference indexes, and lowering now consumes parsed declaration kinds instead of reparsing emitted text. Validation: `moon check --target all` passed on 2026-04-15; `moon test -v` passed with 11 tests on 2026-04-15, including a new grouped-import alias regression test. Exit criteria: imports, re-exports, condcomp, strip, and emit operate on parsed nodes rather than raw substrings. |
| PARITY-002 | `wesl::SourceMapper`, pretty diagnostics in `wesl-rs` | Add span-aware diagnostics instead of message-only errors. | `TODO` | Phase 2. Current public errors expose only enum variants plus `message()`. Add file/module display names, line/column spans, and structured error formatting so users can locate failures without manual repro. Depends on `PARITY-001`. |
| PARITY-003 | `wesl::SourceMapper`, `Wesl::use_sourcemap` | Add source map generation for emitted WGSL. | `TODO` | Phase 2. There is no way to map emitted identifiers or text back to original modules. Target parity is a library API that records loaded modules and mangled identifiers during compile and returns a sourcemap artifact. Depends on `PARITY-001` and benefits from `PARITY-002`. |
| PARITY-004 | `StandardResolver`, `FileResolver`, resolver routing in `wesl-rs` | Expand resolver support beyond `VirtualResolver`. | `TODO` | Phase 3. `moon_wesl` currently ships only an in-memory resolver. Add a filesystem-backed resolver, optional display-name/fs-path hooks, and a router/mount story for mixed virtual + file-backed module graphs. |
| PARITY-005 | `wesl::Wesl` high-level API | Add a high-level compiler facade on top of the low-level `compile(...)` function. | `TODO` | Phase 2. Today callers must manually thread root path, resolver, mangler, and options. Add a discoverable builder/facade that owns defaults, feature toggles, keep lists, and resolver/mangler injection. |
| PARITY-006 | `wesl` validation surface, `wesl-cli check` | Add validation stages for WESL and generated WGSL. | `TODO` | Phase 1. Current behavior is closer to source composition than full validation. Target parity is a validation API that can reject unsupported constructs and optionally validate generated WGSL before returning success. Depends on `PARITY-001`. |
| PARITY-007 | `wesl` lower/eval features | Replace textual lowering with semantic lowering and const-evaluation. | `TODO` | Phase 4. Current lowering only removes top-level `alias` and `const` by textual substitution. Target parity includes constant-expression evaluation, better lowering correctness, and a path toward `@const`-style execution. Depends on `PARITY-001` and `PARITY-006`. |
| PARITY-008 | `PkgBuilder`, `build_artifact`, `include_wesl!` workflow | Add a package/build integration story for reusable shader libraries. | `TODO` | Phase 3. There is no MoonBit-native equivalent for packaging shader modules as build artifacts or reusable generated bundles. Define an artifact format and codegen workflow appropriate for MoonBit consumers. Depends on `PARITY-004` and `PARITY-005`. |
| PARITY-009 | `wesl-cli check`, `wesl-cli compile` | Ship a baseline CLI for compile/check workflows. | `TODO` | Phase 3. The repo currently exposes only a library. Add a CLI that can compile a root module, read from stdin or files, print diagnostics, and expose the same option model as the library facade. Depends on `PARITY-004`, `PARITY-005`, and `PARITY-006`. |
| PARITY-010 | `wesl-cli eval`, `wesl-cli exec` | Add advanced execution tooling for expression evaluation and CPU-side shader execution. | `TODO` | Phase 4. This is well beyond the current project scope, but it is part of the meaningful gap versus `wesl-rs`. Treat it as post-core work after semantic lowering and validation exist. Depends on `PARITY-007`. |
| PARITY-011 | `wesl` experimental `generics` feature | Evaluate and, if appropriate, implement experimental generics/type-generator support. | `TODO` | Phase 4. Do not start here. First stabilize parser, diagnostics, validation, and lowering. When revisited, decide whether MoonBit should match the upstream feature, intentionally omit it, or gate it behind an explicit experimental package or flag. |
| PARITY-012 | `wesl-rs` broader test and conformance posture, local `wesl_test.mbt` | Build a much stronger parity and regression test suite. | `TODO` | Phase 1. The current repo has 10 focused black-box tests, which is good for the initial subset but not enough for parity work. Add golden tests, resolver matrix tests, malformed-input tests, and upstream-inspired fixtures before expanding feature scope. |

## Current Work Queue

- Phase 1: compiler correctness foundation
  - `PARITY-001`: AST-backed compiler core
  - `PARITY-006`: validation stages
  - `PARITY-012`: parity and regression test suite
- Phase 2: diagnostics and library ergonomics
  - `PARITY-002`: span-aware diagnostics
  - `PARITY-003`: sourcemap support
  - `PARITY-005`: high-level compiler facade
- Phase 3: resolver and ecosystem integration
  - `PARITY-004`: standard/file/router resolvers
  - `PARITY-008`: package/build artifact workflow
  - `PARITY-009`: baseline CLI
- Phase 4: advanced language and execution features
  - `PARITY-007`: semantic lowering and const-eval
  - `PARITY-010`: eval/exec tooling
  - `PARITY-011`: experimental generics

## Planning Notes

- Recommended strategy: close Phase 1 completely before starting Phase 3 or 4.
- `PARITY-001` is the keystone item. Without it, the project will keep paying
  complexity tax in every other parity area.
- `PARITY-012` should advance in lockstep with every completed issue rather than
  being deferred to the end.
- `PARITY-010` and `PARITY-011` are intentionally late because they add surface
  area but do not improve the reliability of the current core compiler.
