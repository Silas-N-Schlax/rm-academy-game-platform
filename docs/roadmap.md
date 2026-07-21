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
- **`spec/models/go_fish_turn_spec.rb`** and **`spec/models/crazy_eights_turn_spec.rb`**
  (both "`#save` returns true if turn was valid") — intermittent failures under full-suite load,
  pass reliably in isolation. **Likely fixed 2026-07-21** (previously: root cause not yet
  investigated): root cause was `Game has_many :players` having no explicit order, so
  `GoFish::Game.create`/`CrazyEights::Game.create`'s `players.map` could seat players in a
  different order than `.first` (Rails' implicit id-order) — exactly the assumption these specs'
  setup depends on (`implementation.players.first.hand = ...`). Fixed via `players.sort_by(&:id)`
  in both `.create` methods, with a reproduction spec in each engine's `game_spec.rb`
  (`.create` "when the players are not passed in join order"). Confirmed via ~8 clean full-suite
  runs post-fix; not provably resolved (couldn't force the original failure on demand either) —
  reopen this entry if it resurfaces.
- **`TurnsController#create` has no explicit controller-level authorization** — correctness
  currently rests entirely on the turn form objects (`GoFishTurn`/`CrazyEightsTurn`) validating
  that the submitting user is a valid player. Deferred from the bugs-security batch (see
  `znotes/completed_plans/bugs-security-plan.md` §5); decide whether a lightweight `before_action`
  guard is worth adding, or whether a regression test pinning the current form-object guarantee is
  sufficient. **Model-layer gap closed (2026-07-21):** Go Fish previously had **zero** whose-turn
  enforcement at any layer — unlike `CrazyEightsTurn#is_players_turn?`, nothing checked that the
  submitting user was the current player before a move was applied. Fixed via
  `znotes/completed_plans/card-3-whose-turn-into-engines-brave.md`: both `GoFishTurn` and
  `CrazyEightsTurn` now inherit from a shared `Turn` base class whose unconditional
  `validate :players_turn` calls a new `Game#players_turn?(user_id)` on the AR superclass — closing
  the gap for both games' play *and* Crazy Eights' request/draw path. The broader
  controller-level-authorization question above is still open; this only closed the concrete
  Go Fish model-layer gap.

## Known latent bugs (not yet fixed, 2026-07-21)

- **`app/views/application/_go_fish_form.html.slim:6-7`** has the same players-ordering gap
  described in `docs/architecture.md` (`has_many :players` has no explicit `order`): `collection:
  f.object.players` (unordered) is paired with `selected: f.object.players.first`
  (Rails-implicit id-order), so the pre-selected dropdown option could disagree with the
  displayed collection order under DB load. Found while investigating the `.create`
  player-seating bug above; not fixed — out of scope for that fix.

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
  technical debt but is a larger effort than fits in a 1-2hr card — smaller, scoped extractions
  from this same audit were BRAVE-broken-down into five cards. **Card 1 (server-authoritative
  turn timer) and Card 3 (whose-turn check unified into a shared `Turn` base class) are done** —
  see `znotes/completed_plans/card-1-timer-server-authoritative-brave.md` and
  `znotes/completed_plans/card-3-whose-turn-into-engines-brave.md`. **Card 4a is now done (2026-07-21):** both Part 1 (`CardGame::Card`/`Pile`/`Deck` extraction) and
  Part 2 (`CardGame::Engine`, plus the `start!` hoist to the `Game` AR base via a new `engine_class`
  hook) have shipped — see `znotes/completed_plans/card-4a-extract-shared-card-engine-brave.md`.
  `card-4b-normalize-engine-contracts-brave.md` (signature normalization + `NotImplementedError`
  contracts) now has its prerequisite in place and is ready to pick up; `card-2-remove-debug-logs-
  brave.md` remains untouched in `znotes/plans/` (4a/4b together supersede the older
  `znotes/plans/engine-refactor-plan.md`, which is now annotated as such). Revisit full
  unification once 4b lands.
