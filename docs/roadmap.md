# Roadmap

Future plans and known issues not yet in progress, grouped by theme. Amend entries in place
rather than duplicating when revisiting a topic.

## Known flaky/incomplete tests (2026-07-21)

- **`spec/system/games_spec.rb` "displays offline banner"** — flaky under full-suite load (~1 in
  3-4 runs), passes reliably in isolation. Root cause: `emulate_worker_network`
  (`spec/support/helpers/offline_helper.rb`) applies Chrome DevTools Protocol network emulation to
  the **service worker** devtools target, not the page target, so propagation to the page's
  `navigator.onLine`/`offline` event isn't reliable under CPU load. Two fix attempts (a longer
  Capybara `wait:`, then an explicit `navigator.onLine` poll with an extended timeout) both failed
  to eliminate it and were reverted. Next step: investigate applying the network emulation to the
  page target instead of (or in addition to) the service worker target.
- **`spec/models/go_fish_turn_spec.rb:55`** and **`spec/models/crazy_eights_turn_spec.rb:90`**
  (both "`#save` returns true if turn was valid") — intermittent failures under full-suite load,
  pass reliably in isolation. Root cause not yet investigated.
- **`TurnsController#create` has no explicit controller-level authorization** — correctness
  currently rests entirely on the turn form objects (`GoFishTurn`/`CrazyEightsTurn`) validating
  that the submitting user is a valid player. Deferred from the bugs-security batch (see
  `znotes/completed_plans/bugs-security-plan.md` §5); decide whether a lightweight `before_action`
  guard is worth adding, or whether a regression test pinning the current form-object guarantee is
  sufficient.

## Known coverage gaps (deliberately deprioritized, 2026-07-21)

- **`app/inputs/*.rb`, `app/mailers/*.rb`, `app/icon_builders/*.rb` are at 0% test coverage** per a
  `/rails-audit` SimpleCov run. This is intentional, not an oversight: these are unimplemented-
  feature/generator-boilerplate code, not currently in active use outside of Rails-generator
  scaffolding. Do not re-flag this as a High-severity gap in a future audit without checking
  whether that's changed.

## Architecture debt (2026-07-21)

- **`GoFish::Game` and `CrazyEights::Game` are the most complex and duplicated files in the app.**
  RubyCritic rates `CrazyEights::Game` D (complexity 208.76); Flay found 12 duplicate-code
  occurrences between the two engines (shared `Card` fields/methods, `next_player_turn`,
  `number_of_cards_to_deal`, etc.). A full unification/refactor of the two game engines is real
  technical debt but is a larger effort than fits in a 1-2hr card — four smaller, scoped
  extractions from this same audit are tracked in
  `znotes/plans/audit-improvement-cards-2026-07-21.md`. Revisit full unification once those land.
