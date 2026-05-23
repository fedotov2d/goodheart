---
name: audit-form
description: Use this skill to verify a single clojure.core form or special form against real Clojure semantics and test-coverage breadth. Launches semantics-auditor (parity vs the `clojure` CLI) and spec-coverage-auditor (edge cases in spec/clojure/) in parallel, then rolls up to APPROVED or FIXES NEEDED with concrete file:line routes to interpreter-architect. Use when adding a new form, when changing an existing form's behaviour, or as a pre-flight before committing interpreter changes.
---

You are running the `/audit-form` skill. The skill orchestrates two report-only agents and produces one rolled-up verdict for a single named form.

## Input

A form name. Examples: `if`, `not`, `assoc`, `for`, `defn`, `ns`. Can be a special form (in `SPECIAL` at `lib/clojure/namespace.rb:16`) or a `clojure.core` entry (in `lib/clojure/core.rb`).

If the input is not a recognisable form name — for example, the caller pasted an expression like `(if true 1 2)` instead of `if` — route to `/cross-check` instead. State the redirect; do not silently proceed.

## How to run

1. **Launch two agents in parallel** in a single message with two `Agent` tool calls:
   - `semantics-auditor` with a prompt naming the form and asking for a parity probe set drawn from its standard categories (nil propagation, short-circuit, arity, type coercion, exception kind). For known fase-1 bug forms (`if`, `when`, `when-not`, `and`, `or`, `do`, `not`, `nil`/`true`/`false` literals, negative-number literals, symbol charset), require the matching mandatory probe from `semantics-auditor`'s body.
   - `spec-coverage-auditor` with a prompt naming the form and asking it to enumerate present and missing tests in the matching spec file under `spec/clojure/`.

2. **Wait for both verdicts.** Do not roll up while either agent is still running.

3. **Combine** by these rules:
   - Both APPROVED → final verdict `APPROVED`. No routing.
   - Either BLOCKED → final verdict `FIXES NEEDED`. Concatenate the divergences and missing tests into one list with `file:line` references. Add a single routing line `[→ interpreter-architect: <consolidated reason>]`.
   - `semantics-auditor` returns `FLAG` (reference Clojure not installed) and `spec-coverage-auditor` returns APPROVED → final verdict `FLAG — clojure CLI not installed; parity assertion based on docs only`. Note this in the summary so the caller knows the parity check was downgraded.

4. **Surface the probes**, not just the verdicts. The caller needs to see the actual `(if true 1 (do (raise) :unreached))` style probe outcomes — they are the evidence that lets interpreter-architect choose the right fix.

## Output format

```
AUDIT-FORM — <form name>

SEMANTICS:
  <verdict and probe table from semantics-auditor, verbatim>

COVERAGE:
  <verdict and missing-tests list from spec-coverage-auditor, verbatim>

ROLLED VERDICT: APPROVED / FIXES NEEDED / FLAG — <reason if FLAG>

ROUTING:
  [→ interpreter-architect: <consolidated, one-line list of what to fix>]
```

## When not to use this skill

- The caller pasted an expression, not a form name → use `/cross-check '<expr>'`.
- The caller wants the fix applied, not audited — invoke `interpreter-architect` directly with the form as the change target.
- The caller wants a release-wide audit across all forms — that is the (wave 2) `release-check` skill.
- The form is part of a fase that has not shipped yet (macros, `loop`/`recur`, `try`/`catch`) — emit `OUT OF SCOPE — form not implemented; revisit at fase <N>` and stop.
