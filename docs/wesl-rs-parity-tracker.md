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
| PARITY-001 | `wesl::Wesl`, `wgsl-parse`, local `compile.mbt` | Replace the current text-oriented compiler core with an AST-backed pipeline. | `IN_PROGRESS` | Phase 1. The work was reset on 2026-04-15 after concluding that incremental keyword-matching cleanups were not a viable long-term compiler architecture. Current slices landed: dedicated `error.mbt`, `syntax.mbt`, and `parser.mbt` files now define a compiler-facing `TranslationUnit` / `ImportStatement` / `GlobalDeclaration` layer; `compile.mbt` now consumes `parse_translation_unit(...)` output to build module indexes and import graphs, and the old inline top-level parsing entrypoints have been removed from `compile.mbt`; lowering now consumes parsed global declarations via `parse_global_declarations(...)` rather than reparsing emitted output ad hoc. Since the latest rewrite, `parser.mbt` is no longer a character-index parser: it tokenizes source first and drives import/declaration parsing from `ArrayView[ParserToken]` pattern matching. The newest slice also promotes `syntax.mbt` from a lightweight record bag into a more structured syntax layer: attributes now keep names, argument text, and spans; imports are stored as recursive `ImportNode` trees and flattened later by syntax helpers; global declarations now carry typed headers such as `FunctionDeclaration`, `AliasDeclaration`, `ConstDeclaration`, and `VarDeclaration`. `compile.mbt` now consumes those structured nodes for import flattening, publish detection, duplicate-symbol indexing, entrypoint detection, and lowering decisions instead of relying on flat attribute-name arrays plus ad hoc declaration-kind strings. Remaining gap in this issue: the parser is token-based and the syntax tree is materially richer, but it is still a lightweight hand-written grammar rather than a complete WGSL/WESL syntax tree on the scale of `wgsl-parse`, and later stages such as name resolution, emit, and lowering are still much closer to a textual compiler than to the full `wesl-rs` semantic pipeline. Validation: `moon fmt`, `moon check --target all`, and `moon test -v` all passed on 2026-04-15; `moon test -v` is now 16/16 green after the syntax-tree expansion, including grouped-import alias coverage, nested grouped-import flattening coverage, parse-context coverage, duplicate-symbol context coverage, non-lowered declaration coverage, and a regression covering attribute arguments plus generic `var` declarations. Exit criteria: imports, re-exports, condcomp, strip, and emit operate on parsed nodes throughout, and the parser grows from the current lightweight token grammar into a fuller syntax layer closer to upstream `wgsl-parse`. |
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
| PARITY-012 | `wesl-rs` broader test and conformance posture, local `wesl_test.mbt` | Build a much stronger parity and regression test suite. | `IN_PROGRESS` | Phase 1. On 2026-04-15 the repo gained a vendored upstream corpus under `testdata/upstream/` plus a whitebox harness in `upstream_wbtest.mbt`, `upstream_cases.mbt`, and `upstream_test_support.mbt`. The imported suites now cover spec syntax fixtures, import/context/module fixtures, conditional translation fixtures, dead-code fixtures, bulk-test metadata, ctor-coverage metadata, and e2e syntax smoke coverage for vendored Bevy and WGPU shaders. The harness intentionally separates runnable parity slices from explicitly pending upstream cases: unsupported import-parser rejections, inline package/super reference resolution, module-scope conditional translation forms, and other known gaps are tracked as named pending case lists instead of being dropped silently. Verification: `moon check --target all` and `moon test -v` both pass locally on 2026-04-15, with the expanded suite now at 25/25 green while still carrying explicit pending upstream case names for unimplemented parity gaps. Exit criteria: shrink the pending upstream-case lists over time, add stronger semantic validation/e2e execution beyond current syntax-smoke coverage, and keep each parity issue landing with corresponding upstream-derived regression coverage. |

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
