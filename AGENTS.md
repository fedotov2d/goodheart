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

## Types

RBS files live in `sig/` and mirror `lib/`. Steep checks `lib/`. Specs and `bin/` stay untyped.

Types should be precise enough to help the code and the agent, and simple enough to stay readable. Use `untyped` when a more precise type would be complicated.

Every file under `lib/` has a signature. When working on a Ruby file under `lib/`, read its signature in `sig/` first. `lib/clojure/reader.rb` matches `sig/clojure/reader.rbs`. A method change updates that signature in the same change.
