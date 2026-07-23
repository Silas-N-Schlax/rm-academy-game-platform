# Roadmap

Future plans and known issues not yet in progress, grouped by theme. Amend entries in place
rather than duplicating when revisiting a topic.

## Rummy — new game, in progress (2026-07-22)

- **Rules doc complete:** [docs/rummy_rules.md](rummy_rules.md), reflecting decisions made during
  a BRAVE-style rules brainstorm (Ace low-only, one hand per game, unlimited discard recycling, no
  "rummy" doubling bonus, must-meld-before-lay-off, ranking losers by pip total).
- **UI design approved through v7** (`znotes/rummy/html/` — desktop players-column + full board,
  mobile Melds/Players tabs, slide-out feed drawer, game-over modal, ellipsized long names). Full
  context in `znotes/rummy/ui-design-plan.md` and `znotes/rummy/ascii-mockups.md`.
- **Converted into real, reusable Slim/CSS (2026-07-22):** a new `game-board` BEM component
  (`app/views/application/_game_board*.html.slim`, `app/assets/stylesheets/components/game-board.css`)
  and a reusable `_truncated_text` tooltip partial (`truncated-text.css`) — the latter is also the
  tool to use later for the same long-name-overflow bug in Go Fish/Crazy Eights. Added a new
  `.playing-card--active` "selected" state to the shared `playing-card.css`. All still **hardcoded
  mock data** behind a throwaway `/board_preview` route (`board_preview_controller.rb`) — delete
  that route/controller/view once the real engine exists and wires up actual game state.
- **UI polish pass on the `game-board` component (2026-07-22):** wider, two-row desktop players
  column; a "Melded" badge replacing the convoluted checkmark; working name tooltips (fixed an
  `overflow: hidden` clipping bug on `.game-board__players`); selected hand cards now show a green
  outline (reusing the existing lift-on-hover behavior) instead of the old "Selected: …" text
  readout; melds are now individually clickable/keyboard-focusable toggle buttons
  (`game_board_controller.js#selectMeld`); Stock/Discard piles restructured into a floated top-right
  "true L" layout so melds wrap around them (CSS Grid can't do an L — areas must stay rectangular);
  mobile header, piles placement, and player-card density all reworked. Also found and fixed a real
  bug — a BEM class-name collision (`game-over`) between this component's modal and Go Fish's
  unrelated inline win-screen block was silently overriding the dialog's hidden-by-default state and
  breaking the board's layout; see [docs/architecture.md](architecture.md)'s Asset Pipeline section
  for the full mechanism. Engine/real-data wiring below is still not started.
- **Phase 1 done (2026-07-23): STI skeleton + deal + static render.** `RummyGame < Game` (STI),
  `Rummy::Game`/`Player`/`Card`/`Deck`/`Discard` engine POROs, full `dump`/`load`/`as_json`/
  `from_json` serialization, and a real (no-presenter) board render in
  `app/views/rummy_games/_rummy_game.html.slim`. Resolves the two open questions below:
  - The `number_of_cards_to_deal` two-tier limitation was resolved via an **override** in
    `Rummy::Game#number_of_cards_to_deal` (three tiers: 2 players → 10 cards, 3–4 → 7, 5–6 → 6),
    not a change to the shared `CardGame::Engine` base.
  - The Crazy Eights `Discard` pattern hunch was correct — `Rummy::Discard` mirrors
    `CrazyEights::Discard` (`add_card`/`all_but_top_card`) directly.
  - **Still pending cleanup:** the throwaway `/board_preview` route/controller/view
    (`board_preview_controller.rb`) is now genuinely stale — real game data flows through
    `_rummy_game.html.slim` instead of hardcoded mock data — and should be deleted.
- **Phase 2 planned, not yet built: turn logic.** Draw (+ stock recycling)/meld/lay-off/discard,
  going out, and ranking by pip total. Full design — including a `Rummy::Meld` validity algorithm,
  an Ace-low `run_position` ordering distinct from `CardGame::Card::RANKS`, a `TurnResult`-based
  turn-phase accumulator, and a 24-row validations/edge-cases table cross-checked against
  `docs/rummy_rules.md` — is in `znotes/plans/rummy-phase-2-core-gameplay-brave.md`. **No existing
  meld/run/set detection exists in the codebase yet** — that plan is the reference for building it.

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
  **Card 4b is now done (2026-07-21):** `play`/`valid_move?` are normalized to keyword args across
  both games, the `Game` base declares `play`/`valid_move?`/`engine_class`/`turn_class` as a
  uniform `NotImplementedError` contract, and Go Fish's engine-level `winner`/`winning_player` were
  unified with Crazy Eights' `winner?`/`winning_player` shape — see
  `znotes/completed_plans/card-4b-normalize-engine-contracts-brave.md`. Of the five scoped cards,
  only `card-2-remove-debug-logs-brave.md` remains untouched in `znotes/plans/` (4a/4b together
  supersede the older `znotes/plans/engine-refactor-plan.md`, which is now annotated as such).
  Revisit whether full engine unification is still worth pursuing now that 4a/4b have landed, or
  whether the incremental cards already captured most of the value.
