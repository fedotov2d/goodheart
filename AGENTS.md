# Agent brief

Good Heart is a Clojure interpreter written as a Ruby gem. Idiomatic Ruby evaluates idiomatic Clojure. Library code is in `lib/`.

Read `README.md` for the product and the roadmap.

## Commands

- `bundle install`
- `bundle exec rake spec`
- `bundle exec rubocop`
- `bundle exec steep check --jobs=2`

A code change is finished when the specs, RuboCop, and Steep all pass.

## Scope

Change only what was asked. Walk the roadmap only when asked, and only through steps that have no blocker and no open decision.

When a step has a blocker or an open decision, stop that step. Run two subagents in parallel: one builds the strongest proposal, the other attacks it. Report the proposal that survived, any attack that still stands, and one recommended choice. Continue the steps that are already clear.

## Clojure on Ruby

Follow Clojure's behavior. Implement it with Ruby core and the standard library. Where Clojure uses the JVM internally, use Ruby.

A Java type that this project's Clojure code needs, such as `java.lang.String`, is a Ruby class. Emulate only the methods that code calls. A Ruby value may sit inside the class.

### Evaluator & Reader Invariants

- **Falsy bindings (`false` and `nil`)**: `Clojure::Namespace` subclasses `Hash`. Never use `ns[k] || fallback` to check if a symbol is bound—`false` and `nil` are valid bound values. Always test presence with `key?(k)`.
- **Special forms vs. macros vs. functions**:
  - Normal functions in `Clojure::Core` (`define`) receive already-evaluated arguments.
  - Special forms receive raw AST expressions and must be listed in `Clojure::Namespace::SPECIAL`.
  - Macros are wrapped in `Clojure::Macro` (`define_macro` in Ruby or `defmacro` in Clojure); `Namespace#form_eval` passes raw AST arguments to `.expand` and evaluates the returned form.
- **Test through evaluation**: Calling `Clojure::Core["name"][ns, args]` in specs bypasses `Reader` and `Namespace#form_eval`. Always test control flow, special forms, and macros via `ns.evaluate` or `runtime.read` so argument evaluation and short-circuiting are verified.

## Types & Style

RBS files live in `sig/` and mirror `lib/`. Steep checks `lib/`. Specs and `bin/` stay untyped.

Types should be precise enough to help the code and the agent, and simple enough to stay readable. Use `untyped` when a more precise type would be complicated.

Every file under `lib/` has a signature. When working on a Ruby file under `lib/`, read its signature in `sig/` first. `lib/clojure/reader.rb` matches `sig/clojure/reader.rbs`. A method change updates that signature in the same change.

- **Steep range slicing**: In RBS, `Array#[1..]` returns a nilable `Array[T]?`. Prefer `Array#drop(n)` and `Array#take(n)` so Steep knows the result is non-nil.
- **RuboCop constraints**:
  - Method parameter names must be at least 3 characters (`ctx`, `func`, `ns_name`—not `fn` or `ns`) unless prefixed with `_`.
  - Avoid numeric suffixes on Ruby method names (`macroexpand_once`, not `macroexpand_1`).
  - Use `inject` instead of `reduce`.
  - Keep methods small (cyclomatic/perceived complexity <= 8, ABC <= 17) and RSpec `it` blocks focused (<= 4 expectations, <= 16 lines).
