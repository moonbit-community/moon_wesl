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
| PARITY-001 | `wesl::Wesl`, `wgsl-parse`, local `compile.mbt` | Replace the current text-oriented compiler core with an AST-backed pipeline. | `IN_PROGRESS` | Phase 1. The work was reset on 2026-04-15 after concluding that incremental keyword-matching cleanups were not a viable long-term compiler architecture. Current slices landed: dedicated `error.mbt`, `syntax.mbt`, and `parser.mbt` files now define a compiler-facing `TranslationUnit` / `ImportStatement` / `GlobalDeclaration` layer; `compile.mbt` now consumes `parse_translation_unit(...)` output to build module indexes and import graphs, and the old inline top-level parsing entrypoints have been removed from `compile.mbt`; lowering now consumes parsed global declarations via `parse_global_declarations(...)` rather than reparsing emitted output ad hoc. Since the latest rewrite, `parser.mbt` is no longer a character-index parser: it tokenizes source first and drives import/declaration parsing from `ArrayView[ParserToken]` pattern matching. The newest slices also promote `syntax.mbt` from a lightweight record bag into a more structured syntax layer and start pulling core compiler behavior away from blind text substitution: attributes now keep names, argument text, and spans; imports are stored as recursive `ImportNode` trees and flattened later by syntax helpers; global declarations now carry typed headers such as `FunctionDeclaration`, `AliasDeclaration`, `ConstDeclaration`, and `VarDeclaration`; conditional translation can target non-block regions such as declarations, statements, parameters, and members; and identifier analysis/rewrite now tracks minimal lexical scope so local shadowing does not get rewritten as a global reference. Remaining gap in this issue: the parser is token-based and the syntax tree is materially richer, but it is still a lightweight hand-written grammar rather than a complete WGSL/WESL syntax tree on the scale of `wgsl-parse`, and later stages such as name resolution, emit, and lowering are still much closer to a textual compiler than to the full `wesl-rs` semantic pipeline. Validation: `moon check --target all` and `moon test -v` both pass locally on 2026-04-15; the expanded upstream suite is now 25/25 green with active import and conditional-translation parity coverage. Exit criteria: imports, re-exports, condcomp, strip, and emit operate on parsed nodes throughout, and the parser grows from the current lightweight token grammar into a fuller syntax layer closer to upstream `wgsl-parse`. |
| PARITY-002 | `wesl::SourceMapper`, pretty diagnostics in `wesl-rs` | Add span-aware diagnostics instead of message-only errors. | `TODO` | Phase 2. Current public errors expose only enum variants plus `message()`. Add file/module display names, line/column spans, and structured error formatting so users can locate failures without manual repro. Depends on `PARITY-001`. |
| PARITY-003 | `wesl::SourceMapper`, `Wesl::use_sourcemap` | Add source map generation for emitted WGSL. | `TODO` | Phase 2. There is no way to map emitted identifiers or text back to original modules. Target parity is a library API that records loaded modules and mangled identifiers during compile and returns a sourcemap artifact. Depends on `PARITY-001` and benefits from `PARITY-002`. |
| PARITY-004 | `StandardResolver`, `FileResolver`, resolver routing in `wesl-rs` | Expand resolver support beyond `VirtualResolver`. | `TODO` | Phase 3. `moon_wesl` currently ships only an in-memory resolver. Add a filesystem-backed resolver, optional display-name/fs-path hooks, and a router/mount story for mixed virtual + file-backed module graphs. |
| PARITY-005 | `wesl::Wesl` high-level API | Add a high-level compiler facade on top of the low-level `compile(...)` function. | `TODO` | Phase 2. Today callers must manually thread root path, resolver, mangler, and options. Add a discoverable builder/facade that owns defaults, feature toggles, keep lists, and resolver/mangler injection. |
| PARITY-006 | `wesl` validation surface, `wesl-cli check` | Add validation stages for WESL and generated WGSL. | `IN_PROGRESS` | Phase 1. Current behavior is still much closer to source composition than full validation, but 2026-04-15 now has two concrete validator slices wired into `compile(...)`: loaded modules are checked for global dependency cycles across `alias`, `const`, and `var`, and matrix-related type misuse is rejected in a parser/token-driven validation pass. The current type slice is intentionally narrow but real: it rejects non-floating matrix scalar annotations such as `mat2x2<i32>`, rejects matrix constructors that use explicit integer literals such as `1i`, and rejects explicit-integer element assignment through matrix indexing while still permitting the upstream abstract-int row assignment case. This is enough to activate the vendored upstream circular-context and type-context suites, but WGSL validation, richer type rules, deeper semantic analysis, and a dedicated public validation API remain open. Depends on `PARITY-001`. |
| PARITY-007 | `wesl` lower/eval features | Replace textual lowering with semantic lowering and const-evaluation. | `IN_PROGRESS` | Phase 4, but a first evaluator slice landed early on 2026-04-15 because the vendored upstream spec-eval corpus was already in place and narrow enough to drive real progress. `moon_wesl` now has a dedicated `const_eval.mbt` module with a tokenized `ArrayView` parser/evaluator for a constrained `@const fn test() -> T { ... }` subset used by the upstream literal/type-inference cases. The current evaluator handles `let`/`var` bindings, `return`, unary negation, `+` / `-` / `/`, nested parentheses, `clamp(...)`, abstract-vs-concrete integer inference across `i32` / `u32` / `f32`, decimal and hexadecimal integer literals, decimal and hexadecimal float literals, range checking, and exact `f32` round-trip validation for cases such as `0x1.0000000001p0`. This is enough to activate the vendored `spec eval` suite, but it is still intentionally narrow: it is not yet wired into lowering, it does not evaluate arbitrary shader programs, and it does not cover the broader `wesl-rs` eval/exec surface. Validation: `moon check --target all` and `moon test -v` both pass locally on 2026-04-15 after landing the upstream eval slice. |
| PARITY-008 | `PkgBuilder`, `build_artifact`, `include_wesl!` workflow | Add a package/build integration story for reusable shader libraries. | `TODO` | Phase 3. There is no MoonBit-native equivalent for packaging shader modules as build artifacts or reusable generated bundles. Define an artifact format and codegen workflow appropriate for MoonBit consumers. Depends on `PARITY-004` and `PARITY-005`. |
| PARITY-009 | `wesl-cli check`, `wesl-cli compile` | Ship a baseline CLI for compile/check workflows. | `TODO` | Phase 3. The repo currently exposes only a library. Add a CLI that can compile a root module, read from stdin or files, print diagnostics, and expose the same option model as the library facade. Depends on `PARITY-004`, `PARITY-005`, and `PARITY-006`. |
| PARITY-010 | `wesl-cli eval`, `wesl-cli exec` | Add advanced execution tooling for expression evaluation and CPU-side shader execution. | `TODO` | Phase 4. This is well beyond the current project scope, but it is part of the meaningful gap versus `wesl-rs`. Treat it as post-core work after semantic lowering and validation exist. Depends on `PARITY-007`. |
| PARITY-011 | `wesl` experimental `generics` feature | Evaluate and, if appropriate, implement experimental generics/type-generator support. | `TODO` | Phase 4. Do not start here. First stabilize parser, diagnostics, validation, and lowering. When revisited, decide whether MoonBit should match the upstream feature, intentionally omit it, or gate it behind an explicit experimental package or flag. |
| PARITY-012 | `wesl-rs` broader test and conformance posture, local `wesl_test.mbt` | Build a much stronger parity and regression test suite. | `IN_PROGRESS` | Phase 1. On 2026-04-15 the repo gained a vendored upstream corpus under `testdata/upstream/` plus a whitebox harness in `upstream_wbtest.mbt`, `upstream_cases.mbt`, and `upstream_test_support.mbt`. The imported suites now cover spec syntax fixtures, import/context/module fixtures, conditional translation fixtures, dead-code fixtures, bulk-test metadata, ctor-coverage metadata, and e2e syntax smoke coverage for vendored Bevy and WGPU shaders. The newest parity slices no longer just vendor those cases: they keep the upstream spec-declaration list, spec-expression list, spec-eval list, import-syntax list, import-compilation list, conditional-translation list, circular-context list, and type-context list active instead of pending. Concretely, `moon_wesl` now rejects reserved words and invalid declaration names in parser-driven declaration headers, accepts grouped and bare module imports such as `import foo;`, rejects empty imports such as `import;`, resolves inline `package::...` / `super::...` qualified references, supports namespace-style imports like `import super::file1;`, applies `@if` / `@else` to non-block regions such as declarations, statements, parameters, and members, preserves local shadowing during both reference collection and identifier rewriting, ignores comment text during parser/reference passes so upstream-derived regressions remain meaningful, rejects recursive global `alias` / `const` / `var` declarations with explicit cycle errors, actively validates the vendored matrix type-context corpus, has a dedicated token-driven expression parser slice for upstream numeric-literal syntax coverage, and now executes the vendored literal/type-inference `spec eval` corpus through a real tokenized const-evaluator. Verification: `moon check --target all` and `moon test -v` both pass locally on 2026-04-15, with the expanded suite now 29/29 green after removing the spec-eval pending area as well. Remaining explicit pending areas are now concentrated in broader/public const-eval coverage, stronger semantic validation, and deeper e2e execution beyond current syntax-smoke coverage. Exit criteria: keep shrinking the remaining pending upstream-case lists, add stronger semantic validation/e2e execution beyond current syntax-smoke coverage, and keep each parity issue landing with corresponding upstream-derived regression coverage. |

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
