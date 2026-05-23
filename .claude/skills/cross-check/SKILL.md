---
name: cross-check
description: Use this skill to diff a single Clojure expression's behaviour between the local `clojure` CLI and goodheart's `bin/goodheart`. Reports MATCH or DIVERGE with both raw outputs verbatim. The fastest way to confirm or refute a suspected semantic bug. Falls back to FLAG (docs-only) when the `clojure` CLI is not installed.
---

You are running the `/cross-check` skill. The skill is a thin wrapper around `semantics-auditor` for the single-expression case.

## Input

A single Clojure expression as a string. Examples:

- `(not nil)`
- `(if true 1 (do (println :unreached) 2))`
- `(= [1 2] '(1 2))`
- `(merge {:a 1} {:b 2})`

The expression must be self-contained — no free symbols that goodheart does not have defined. If the caller passes an expression that references undefined symbols, route it back with `EXPRESSION REFERENCES UNDEFINED SYMBOL <name> — define it or pick a self-contained probe`.

## How to run

1. **Detect the reference Clojure CLI:**

   ```bash
   which clojure 2>/dev/null
   which clj      2>/dev/null
   ```

   If neither is on `PATH`, proceed in FLAG mode — note this in the output and run only the goodheart side, comparing against the caller's stated expectation or the clojure.org docstring.

2. **Run the expression on the reference side** (when available):

   ```bash
   timeout 5 clojure -M -e '<expr>' 2>&1
   ```

3. **Run the expression on the goodheart side:**

   ```bash
   echo '<expr>' | timeout 5 bundle exec bin/goodheart 2>&1 | tail -3
   ```

   The REPL prompt is `user => ` and the printed result is the inspected value of the last form. Read `bin/goodheart` if the parsing of stdout is unclear.

4. **Diff** stdout, return-value rendering, and exception kind. Categorise:
   - `MATCH` — both sides return the same value (or both raise the same kind of error).
   - `DIVERGE — value` — different return values.
   - `DIVERGE — side effect` — one side printed/raised in a branch the other did not. This is the laziness-bug indicator.
   - `DIVERGE — type` — same numeric magnitude but different type (e.g. integer vs float).
   - `DIVERGE — exception` — different exception kinds.

5. **For a DIVERGE outcome**, identify the form most likely responsible (`if`, `not`, the reader rule, etc.) and add a routing line.

## Output format

```
CROSS-CHECK — <expr>

REFERENCE: <path to clojure CLI, or "not installed — FLAG mode">

GOODHEART:
  cmd:    echo '<expr>' | bundle exec bin/goodheart
  output:
    <verbatim>

CLOJURE:
  cmd:    clojure -M -e '<expr>'
  output:
    <verbatim>

VERDICT: MATCH / DIVERGE — <category> / FLAG — <reason>

ROUTING:
  [→ interpreter-architect: divergence localised to <form>]   (only on DIVERGE)
```

## When not to use this skill

- The caller passed a form name instead of an expression — route to `/audit-form <name>`.
- The expression depends on a fase not yet shipped (macros, `loop`/`recur`, host-fn bridge) — emit `OUT OF SCOPE — depends on <fase>; revisit at fase <N>`.
- The caller wants a batch of expressions — run `/cross-check` once per expression rather than batching; the per-expression probe table is the artefact, batching destroys it.
- The caller wants a fix proposal — that is `interpreter-architect`'s job; this skill produces the evidence only.
