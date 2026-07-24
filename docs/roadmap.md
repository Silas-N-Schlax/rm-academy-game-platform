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
  - **Cleanup done (2026-07-24):** the throwaway `/board_preview` route/controller/view
    (`board_preview_controller.rb`) was deleted now that real game data flows through
    `_rummy_game.html.slim` instead of hardcoded mock data.
- **Phase 2 built and green (2026-07-23): full turn logic.** Draw (+ stock recycling), meld,
  lay-off, discard, going out, and ranking by pip total are all implemented end to end — engine
  POROs (`Rummy::Meld`, `Rummy::TurnResult`, `Rummy::Game#draw`/`#lay_down_meld`/`#lay_off`/
  `#discard_card`/`#winner?`/`#ranking`), the `RummyTurn` form object, `RummyGame#play`/
  `#valid_move?`, `TurnsController` wiring, and the full UI (draw-pile forms, hand-checkbox
  selection, JS-driven lay-off-by-clicking-a-meld, morph-safe selection state, an error toast, and
  a real ranked game-over modal). Full design doc (now annotated with what shipped, several
  mid-implementation deviations, and every real bug found along the way) is
  `znotes/plans/rummy-phase-2-core-gameplay-brave.md` — see its "Handoff notes" section at the
  bottom before starting further work. `bundle exec rspec` is green (679 examples, run twice for
  flake-checking); `bin/rubocop`/`bin/brakeman`/`bin/bundler-audit` all clean. **Not yet done:**
  manual browser playtesting (the implementing session only ran automated specs) — the plan's own
  handoff notes flag several UI rough edges worth a manual pass before considering this fully done.
- **Manual review pass, 12 items (2026-07-23):** 10 of 12 fixed — hand-card sizing/overlap fix (see
  [docs/architecture.md](architecture.md)'s Asset pipeline section for the `display: contents` root
  cause), game-over button now only renders once the game has ended and the modal auto-opens
  (`dialog_controller.js` repurposed from dead code, now calling `showModal()`), turn badge now
  matches the other games' primary/notice coloring, an "Empty" placeholder for the emptied discard
  pile, the error toast recolored to warning with a close button, a "Clear selection" button, full
  melds now disable/fade (new `Rummy::Meld#full?`), meld-button hover/highlight cleanup (dead
  `selectMeld` JS removed), consistent Optics button outlines plus a disabled "draw first" icon on
  Meld/Discard, and two real engine bugs found and fixed with model+request+system specs: (1) a
  win-condition gap — discarding the just-drawn discard card is now allowed when it's the only card
  left (see [docs/rummy_rules.md](rummy_rules.md)), (2) a critical bug where nothing stopped further
  turns once a game ended, letting the winner draw/discard indefinitely (fixed via a new
  `game_not_finished` validation on the shared `Turn` base class — see
  [docs/architecture.md](architecture.md)'s Turn form objects section). **Item 10 explicitly
  deferred, not MVP:** clicking "Discard" shouldn't unselect an already-checked card if you meant to
  click something else — no fix attempted, revisit if it comes up again. **Latent bug fixed
  (2026-07-24):** the toast/offline-banner markup used `.alert_messages`/`.alert_title`/
  `.alert_description` (single underscore) instead of Optics' actual BEM classes
  `.alert__messages`/`.alert__title`/`.alert__description` (double underscore), so those inner
  elements never got Optics' intended spacing/font styling — corrected as part of the UI polish
  pass below.
- **UI polish pass, 5 items (2026-07-24):** the turn badge now shows a filled-vs-hollow circle icon
  (`li-circle-dot`/`li-circle`) to distinguish whose turn it is, since Lucide (the icon set here) has
  no true solid-circle glyph; the error toast and offline banner (see the BEM class-typo fix above)
  were repositioned from a full-bleed bar rendering above the header into a proper floating toast —
  fixed `position`, a slide-in/out transition using `@starting-style`/`display: ... allow-discrete`
  (the same modern-CSS pattern Optics' own accordion component already uses), and a borderless
  dismiss button via Optics' `btn--no-border`; the game-over ranking list now gives 2nd/3rd place a
  subtle silver/bronze-ish color emphasis while other ranks stay plain; the topbar's stock-count pill
  styling (previously mobile-only, plain text on desktop) is now consistent across breakpoints and
  height-matched to the turn badge; and the Rummy meld/discard "must draw first" lock icon —
  previously hardcoded `hidden=true` in the Slim template, relying entirely on JS to correct it after
  page load — now derives `hidden`/`disabled` directly from `presenter.awaiting_draw` server-side (a
  non-JS reproduction spec proved the bug before the fix). Also deleted the now-fully-stale
  `/board_preview` dev route (see Phase 1 above).

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

## UI/view-layer debt (2026-07-24)

- **`RummyPresenter` extraction — done (2026-07-24):** Rummy's inline `board` hash
  (`app/views/rummy_games/_rummy_game.html.slim`) is now a `RummyPresenter` PORO
  (`app/presenters/rummy_presenter.rb`) with a granular method-per-value API, wired via a new
  `presenter_class` contract on the `Game` models (mirroring `turn_class`/`engine_class` —
  raises `NotImplementedError` by default). `show.html.slim` builds one presenter (carrying
  `turn`/`turn_timer_seconds`) as the sole local passed to each game partial. Go Fish/Crazy Eights
  get a `NullPresenter` stub (`app/presenters/null_presenter.rb`) so the shared show view doesn't
  error on them; they still build their own display data inline pending their own conversion. No
  shared `GamePresenter` base class yet — deferred until that conversion gives a second real data
  point to factor against.
- **`game-board.css` decomposition** (`znotes/plans/game-board-css-decomposition.md`): shrink the
  558-line `game-board.css` down to just its layout shell by extracting each section (feed drawer,
  game-over modal, players panel, piles, hand/actions) into small reusable component files, leaning
  on Optics built-ins (`side-panel`, `modal`, `card`, `tab-group`) where they fit. Intended to give
  Go Fish/Crazy Eights reusable pieces once they convert to the new board design. Not started.
  **Superseded in part (2026-07-24):** the Go Fish/Crazy Eights migration plan below decided those
  two games do NOT reuse the `player-list` sidebar this bullet assumed — they get a seated
  `game-table` layout instead. The feed drawer/game-over modal/hand pieces are still reusable.
- **Go Fish & Crazy Eights migration to the game-board design + presenters — planned, not started
  (2026-07-24):** a BRAVE-style breakdown (two rounds of artifact mockups) produced a full
  migration plan, now split into `znotes/plans/gf-c8-migration/README.md` (decisions/context) plus
  ordered, commit-sized TDD execution docs `go-fish.md` (done first, builds the shared infra) and
  `crazy-eights.md` (reuses it) in the same folder. Key decisions:
  each game gets its own PORO presenter (`GoFishPresenter`/`CrazyEightsPresenter`, matching
  `RummyPresenter`'s shape — no shared base class yet, rule of three); both drop their turn forms
  entirely for a click-a-card-then-click-a-target interaction via a new shared single-select
  `card-select` Stimulus controller (mirroring Rummy's `layOff` requestSubmit pattern); both are
  seated around a central `game-table` grid (evolved from the existing
  `components/game-table.css`, generalized to fit 1–6 opponent seats) with the center region blank
  for Go Fish and holding the draw/discard piles for Crazy Eights; a new shared bottom-center
  "what just happened" action notice (`aria-live="polite"`, reusing
  `game_board_toast_controller`'s value-changed→auto-dismiss pattern) was designed for all games,
  worded per-viewer from the same narration source as the feed. An engine audit found
  `GoFish`/`CrazyEights` `TurnResult`s lack Rummy's `occurred_at`/`feed_lines(viewer_id)`/
  `actor_label(viewer_id)`/`ranking` — the plan adds these for real parity rather than working
  around the gap in the presenters. **Turn timer/auto-play wiring is explicitly deferred** to a
  separate future initiative — keep `timer_controller.js`/`auto_play_controller.js`, just don't
  wire them into the new boards yet. Sequencing: one PR, Go Fish fully end-to-end first (the
  harder one — new presenter + new UX), then Crazy Eights reusing that foundation; old code
  (`_player_accordion`, old feeds, `ask_button_controller.js`, `gf-game` grid, etc.) gets deleted
  only after each game's new board is verified and safely committed, not interleaved with the
  other game's build.
  **Go Fish execution progress (2026-07-24):** sections A (engine/PORO parity —
  `occurred_at`/`feed_lines`/`actor_label`/`ranking`/`to_file_name`), B (`GoFishPresenter`), C (the
  `game-table` layout + seated-tile partial + atomic presenter flip), D (the shared `card-select` +
  `gofish-turn` Stimulus controllers, click-a-card-then-click-a-seat interaction, server-rendered
  `disabled` hand cards), and most of E (feed drawer + game-over modal, both reusing the shared
  `_game_board_feed`/`_game_board_game_over` partials) are done per
  `znotes/plans/gf-c8-migration/go-fish.md`. Wiring the shared game-over partial to Go Fish required
  generalizing it beyond Rummy's hardcoded "pip total"/"pips" text: both presenters now expose a
  `ranking_subtitle` method and each `ranking` entry carries a generic `score:` string, additive to
  Rummy's existing `pips:` key (Rummy's own spec/rendered output updated to match, confirmed
  byte-identical via its full system-spec suite). The old GoFish-specific game-over specs in
  `spec/system/games_spec.rb`/`spec/system/turns_spec.rb` (testing the removed dropdown UI and
  literal "Game Over"/"won the game!" text) were deleted as redundant with the new coverage in
  `spec/system/go_fish_spec.rb`. **E3 done too:** a new `action-notice` component (own CSS file,
  `action_notice_controller.js` generalizing `game_board_toast_controller.js`'s value-changed→
  show→auto-dismiss pattern, `aria-live="polite"`) shows the latest turn's last feed line
  bottom-center, distinct from the top-right error toast; `GoFishPresenter#action_notice` sources it
  from the same `feed`/`feed_lines(viewer_id)` data the drawer uses. Built generically so Rummy can
  adopt it later — Rummy untouched this pass. All of section E is now done; only F (old-code
  cleanup) remains before Go Fish moves to Crazy Eights. **A
  real test-coverage gap opened by this work:** the only system-level coverage of
  `timer_controller.js`/`auto_play_controller.js` lived in `spec/system/games_spec.rb`, riding on Go
  Fish's old UI — that whole block was deleted (not deferred) since the feature it drove no longer
  renders and won't again until a future initiative wires the timer into the new boards. Until that
  happens, the turn timer has zero system-spec coverage anywhere in the suite.
- **Game-hand layout bugs (2026-07-24):** the empty/off-center hand issue (label sitting at the
  bottom when the hand is short, action buttons hugging the bottom instead of centering) is fixed —
  `.game-hand`'s `align-items` changed from `flex-end` to `center` in `game-hand.css`. **Still open:**
  when the hand has exactly one card (or every card is selected at once), hovering/selecting raises
  the card via a negative `margin-top` (`playing-card.css`), which visibly shrinks the whole
  `.card-collection`/`.game-hand` container instead of just lifting the card. A fix attempt — adding
  `padding-top` on `.card-collection--*` equal to the hover offset, expecting the reserved padding to
  absorb the flex line's margin-driven height reduction — was tried and empirically disproven
  (measured via `getBoundingClientRect()` in a throwaway system spec): the container still shrinks by
  exactly the hover offset regardless of the padding, because padding and margin don't interact the
  way that fix assumed. Reverted. The user explicitly wants to keep the negative-margin lift technique
  (not switch to `transform: translateY(...)`, which was also considered and rejected as "brings the
  div to the top and looks weird") — next attempt needs a different mechanism for reserving space
  that doesn't rely on padding offsetting margin.
- **Player-list panel redesign (2026-07-24):** `RummyPresenter#opponents` now returns
  `last_action` (each opponent's most recent turn, via `TurnResult#feed_lines` — see
  [docs/architecture.md](architecture.md)'s feed-rendering section for the viewer-id gotcha this
  surfaced), `current_turn` (highlights whichever opponent row is up next), and `avatar_url`
  (hardcoded to a new `RummyPresenter::DEFAULT_AVATAR_URL` = `/default_avatar.png`, the same
  placeholder image `users/show.html.slim` already uses — swap for the real per-user avatar once
  that feature exists). The row itself (`_game_board_player.html.slim`/`player-list.css`) was
  reworked to avatar+name on the left, melded badge (now a small circular checkmark button using
  Optics' `[data-tooltip-text]` tooltip — already covers hover *and* focus/click out of the box, no
  override needed) + mini card-fan + `+n` overflow on the right, with the old total-hand-size
  number dropped entirely. Two open threads from this pass:
  - `.card-collection` bakes in `padding: 0 var(--op-space-medium)` regardless of size modifier —
    caused a real, non-obvious gap between the mini-fan and the `+n` text; fixed locally via
    `.card-collection.player-list__mini-card { padding: 0; }`, but the same trap could bite the next
    new modifier added to that component.
  - `.player-list` keeps `overflow: hidden` (needed to clip row backgrounds/shadows to the card's
    rounded corners), but this also clips the Optics tooltip popup on the truncated last-action
    text. A fix (scoping border-radius to `:first-child`/`:last-child` instead of clipping the
    whole container) was tried and reverted — the last-action tooltip may currently be invisible
    when it pops outside the container's bounds. Revisit if that's confirmed.
