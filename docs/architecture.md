# Architecture

## Core models and how they relate

```
User --< sessions (Session)
User --< players (Player) >-- Game
Game (STI base, type: "GoFishGame" | "CrazyEightsGame")
  has_many :players, dependent: :destroy
  has_many :users, through: :players
```

- `Game` is an STI base class (`type` column). `GoFishGame` and `CrazyEightsGame` are the only subclasses today; adding a new game means adding a new subclass plus a new engine namespace (see below), not touching the base class's schema.
- `has_many :players`/`has_many :users` have no explicit `order`. Rails implicitly orders `.first`/`.last` by `id`, but `.map`/`.each`/`.to_a` do not — those can return rows in a different order under DB load. `GoFish::Game.create`/`CrazyEights::Game.create` learned this the hard way (players could get seated in the wrong turn order) and now `sort_by(&:id)` explicitly before mapping. `app/views/application/_go_fish_form.html.slim`'s player-select dropdown has the same latent gap and is not yet fixed — see `docs/roadmap.md`.
- `Player` is the join model between `User` and `Game` — one row per seat, holding `winner` (boolean/nil: `true` = won, `nil` = lost or unfinished, since ties aren't possible in either game).
- `Session`/`Current` follow the standard Rails 8 authentication-generator pattern: a signed cookie holds a `session_id`, `Current.session` is set per-request in `Authentication` (a controller concern), and `Current.user` delegates to it.
- `Stat` is a plain (non-AR) query object that computes win/loss/average stats per user, optionally filtered by game `type` string.

## The serialized game-state pattern

This is the part that isn't obvious from skimming any single file. Each `Game` subclass declares:

```ruby
class GoFishGame < Game
  serialize :game_state, coder: GoFish::Game
end
```

`game_state` is a `jsonb` column on `games`, but what's stored in it is the **entire live state of one game** — deck, hands, discard pile, turn index, per-turn result history — as a plain Ruby object graph, not normalized rows. The engine class (`GoFish::Game`, `CrazyEights::Game`) acts as the Rails serializer coder by implementing the interface `ActiveRecord::AttributeMethods::Serialization` expects:

- `self.dump(game)` → calls `game.as_json`
- `self.load(json)` → calls `self.from_json(json)`, reconstructing the whole object graph (players, deck, discard, results) from the hash
- `as_json` / `from_json` are mirror images of each other on every nested object (`Card`, `Deck`, `Player`, `Book`/`Discard`, `TurnResult`) — if you add a field to one of these classes, you must update **both** directions or round-tripping through the DB will silently drop it.

Why this shape: it lets each game's rules live entirely in plain Ruby (easy to unit test, no AR overhead, no complex joins for "whose turn is it"), while still getting persistence, `jsonb` querying, and Rails' normal record lifecycle for free on the outer `Game` row.

`Game#implementation` memoizes `game_state` for the lifetime of the in-memory `Game` instance — be aware that mutating the engine object and not reassigning it back to `self.game_state` won't get picked up by ActiveRecord's dirty tracking (see how `GoFishGame#play` and `CrazyEightsGame#play` explicitly do `implementation = self.game_state; ...; self.game_state = implementation` before `save!`).

## Shared `CardGame::` base classes

`GoFish::Card`/`CrazyEights::Card` inherit from `CardGame::Card` (`app/models/card_game/card.rb`); `GoFish::Deck`/`CrazyEights::Deck` inherit from `CardGame::Deck < CardGame::Pile`, and `CrazyEights::Discard` inherits directly from `CardGame::Pile`. Each concrete subclass declares its own `def self.card_class` (e.g. `GoFish::Deck.card_class = GoFish::Card`) so the shared `generate_deck`/`from_json` code builds the right namespace's `Card` — deliberately explicit rather than derived from the module name, per the no-magic convention. Note `CardGame::Card#==` only compares `rank`/`suit`, not class — a round-trip spec using `eq`/`have_attributes(cards: ...)` won't catch a `card_class` misconfiguration that builds the wrong subclass; assert `be_an_instance_of(card_class)` explicitly if you touch this code (see `spec/support/shared_examples/card_game_pile_examples.rb`/`card_game_deck_examples.rb`).

`GoFish::Game`/`CrazyEights::Game` inherit from `CardGame::Engine` (`app/models/card_game/engine.rb`), which owns `start`/`deal` (+ a no-op `after_deal` hook — `CrazyEights::Game` overrides it to flip a card to the discard pile), `next_player_turn`, `current_player`/`find_player`/`latest_result`, `number_of_cards_to_deal` (reads `self.class::SMALL_GAME_MAX_SIZE`, not a base constant), and the `self.load`/`self.dump`/`self.create` class-method plumbing. `self.create` builds via `self.new(players: ...)` — polymorphic dispatch to whichever subclass's own `initialize` — plus a `self.player_class` hook (same pattern as `card_class` above), so **neither engine's `initialize` was hoisted**: `CrazyEights::Game` carries extra state (`discard`, `wild_suit`, `current_result`) that doesn't belong on the shared base, and each subclass's `initialize` must still accept a bare `players:` keyword for `self.create` to work. One incidental side effect: `next_player_turn` was private on `CrazyEights::Game` before this extraction (Go Fish's copy was already public, and its explicit `nil` return is load-bearing for `#go_fish`) — it's public on both now that it's defined once on the shared base.

`winner?`/`winning_player` are **not** part of `CardGame::Engine`'s shared contract — each game's win condition is different enough that a shared base method wouldn't add value — but both `GoFish::Game` and `CrazyEights::Game` are expected to expose that same shape. Critically, `winning_player` must return `nil` rather than raise when there's no winner yet: Crazy Eights' `players.find(&:empty_hand?)` is naturally nil-safe, but Go Fish's book-tie-breaking logic originally wasn't (`nil.value` on `highest_book` when no player had any books) and needed an explicit `return unless winner?` guard. A third engine's `winning_player` must satisfy this same nil-safety invariant.

## Turn form objects

Moves are **not** stored as their own database rows. Instead, `GoFishTurn` / `CrazyEightsTurn` are `ActiveModel`-based form objects (not `ActiveRecord`) that:

1. Take the submitted params plus `game` and `user` from `TurnsController#create`.
2. Validate the move (presence, whose turn it is, whether the move is legal given current game state) using each game's own validation rules.
3. On `save`, if valid, call `game.play(...)` with the right arguments for that game type, which mutates and re-persists `game_state`.

This exists specifically so each game type can define its own validation logic (Go Fish validates `player`/`rank`; Crazy Eights validates `rank`/`suit`/`wild_suit`/`request`) while `TurnsController` stays a single, game-agnostic controller — it just calls `@game.turn_class.new(turn_params)`. This is also why `Game` requires subclasses to implement `turn_class`. `play`/`valid_move?` are required (`NotImplementedError`) contract methods too, and — deliberately, as of Card 4b — both are keyword-only and uniform in shape across every subclass, so a new game type has one calling convention to satisfy rather than guessing positional-vs-keyword per game.

Both `GoFishTurn` and `CrazyEightsTurn` inherit from a shared `Turn` base class (`app/models/turn.rb`), which owns the `game`/`user` presence+inclusion validation and an *unconditional* `validate :players_turn` — it calls `Game#players_turn?(user_id)` on the AR superclass, which checks `implementation.current_player.id == user_id`. This check is deliberately unconditional (not folded into `valid_move?`) because Crazy Eights' `valid_move` validation early-returns on card *requests* (draws) — a whose-turn check living only inside `valid_move?` would silently stop guarding the request path. Putting it in the base class instead guards play and request/draw moves the same way for both games.

Simple Form's `f.button :submit` renders an `<input type="submit">`, not a `<button>` tag — `.textContent` is a no-op on an input, so a Stimulus controller updating its visible label (e.g. the Go Fish "Ask" button) must set `.value` instead.

When a failed turn's validation errors need to reach the view (e.g. Rummy's error toast), `TurnsController#create` re-renders `"games/show"` on `turn.save` failure — but per the one-instance-variable-per-controller-action convention (see AGENTS.md), that non-persisted `turn` is passed as `locals: { turn: turn }`, not a second instance variable. Locals don't auto-propagate into nested `render partial:` calls, so it has to be re-threaded by hand at each hop: `games/show.html.slim` forwards it into `render partial: @game, locals: { turn: local_assigns[:turn], ... }`, and the game-type partial (e.g. `_rummy_game.html.slim`) reads it back out via `local_assigns[:turn]` (`nil` on the normal `GamesController#show` render path, where no `turn` local is passed at all).

The shared `Turn` base class also runs an unconditional `validate :game_not_finished` (`errors.add(:base, ...)` if `game.finished_at` is present). This closed a real bug found during a Rummy Phase 2 manual review (2026-07-23): nothing previously stopped further turns once a game ended — `finished_at`/the winning `Player#winner` flag were set correctly by `end_game`, but since the winner's `current_player_idx` never advances past them, `Game#players_turn?` kept returning true for that player, so they could keep drawing/discarding indefinitely and silently "un-win" by drawing new cards back into what should have stayed an empty, game-over hand. Fixed at the shared base class rather than per-game, so it protects Go Fish and Crazy Eights the same way.

## Real-time updates

There's no bespoke `ActionCable` channel for gameplay. Instead:

- `Game` broadcasts via Turbo Streams: `after_create_commit`/`after_update_commit` call `broadcast_refresh_later_to "games"` (for lobby/list views) and `broadcast_refresh_later_to self` (for the individual game page).
- `Player` also broadcasts to `"games"` on create/update so the lobby list picks up seat changes.
- `app/views/games/show.html.slim` subscribes with `turbo_stream_from @game` and re-renders via `render @game`, which uses Rails' polymorphic partial lookup — `GoFishGame` renders `go_fish_games/_go_fish_game`, `CrazyEightsGame` renders `crazy_eights_games/_crazy_eights_game`. Per-game "view-model" data for shared display partials (e.g. the `board` hash Rummy passes to the shared `_game_board` partial) is built directly in each game's own view from `implementation`, not via a separate presenter/view-model class — matching how Go Fish and Crazy Eights already inline this in their own partials. This is deliberate, not an oversight: the shared partial's generic hash parameter invites reaching for a presenter, but the project's convention is to stay consistent with the existing direct-`implementation`-call style instead.
- The Go Fish turn timer (`timer_controller.js`) is a good example of a Turbo-morph gotcha: the countdown restarts from a dedicated Stimulus `anchor` value (`game.updated_at.to_f`), not from the remaining-seconds value itself. Morph only fires a Stimulus `valueChanged` callback when the attribute **string** actually changes on re-render — on a go-again turn the recomputed remaining-seconds can coincidentally match the prior render's value, which would silently fail to reset the countdown if that value were the restart trigger. `GoFishGame#remaining_turn_seconds` also assumes `updated_at` marks turn-start (true today because only `start!`/`play`/`end_game` write the `games` row mid-game) — a future `touch:` association or incidental `game.update` elsewhere would silently desync the timer.
- A related but distinct morph gotcha: Idiomorph (the library behind `turbo-refresh-method: morph`, enabled in `_head.html.slim`) matches old/new DOM nodes **by `id`** and, when it finds a match on a form element, preserves that element's *live* value/checked state rather than overwriting it with the freshly-rendered HTML. This means in-progress client-side state (e.g. a checked-but-unsubmitted checkbox) can survive an unrelated `broadcast_refresh_later_to` refresh — but only if the element has a stable, unique `id` for Idiomorph to match against. Any interactive multi-select UI built on top of the broadcast-refresh loop needs stable ids on its inputs, or a background refresh can silently reset a player's in-progress selection. Because morph preserves the underlying input state but doesn't re-fire a `change` event, code that derives visual state (CSS classes, button enablement) from those inputs should re-sync on the `turbo:morph` document event, not rely solely on `change` listeners.
- `finished_at` is only set as a **side effect of `Game#play`/`end_game`**, not automatically whenever `winner?` becomes true. Code (including specs) that mutates `game_state` directly into a winning state without going through `play` will have `finished_at` still `nil` — anything reading it (e.g. the game-over display) must not assume it's set just because `winner?` is true.
- **A same-page form-submit redirect is also a morph, and it's asynchronous.** When a Turbo-intercepted form POST redirects back to the page it was submitted from (e.g. `TurnsController#create`'s `redirect_to game_path(@game)`), Turbo Drive treats the resulting GET as a same-page visit and applies `turbo-refresh-method: morph` — it does **not** behave like a synchronous full reload. A system spec that immediately follows one form interaction with another (check a box, then click a button) can race ahead of the morph settling, silently losing form state (e.g. `card_ids` missing from the next POST) with no error raised — found while building Rummy's lay-off/meld system specs, several of which were intermittently flaky until each `:js` spec asserted on the settled post-morph state (e.g. an updated hand card count) before its next interaction. This is a distinct gotcha from the stable-id/Idiomorph one above — that one is about *what* gets preserved across a morph; this one is about *timing* between a morph-triggering navigation and whatever the test does next.
- **Two feed-rendering patterns coexist.** Go Fish and Crazy Eights render turn-by-turn history via
  their own per-game partials (`_go_fish_feed.html.slim`, `_crazy_eights_feed.html.slim`), which
  take a `result`/`current_player` local and branch on viewer identity **inside the template**
  (`result.messages_for_current` vs. `result.messages_for_all`). Rummy — and any future new game —
  instead renders through the shared `_game_board_feed.html.slim`, which takes a flat
  `board[:feed]` array of already-resolved `{time:, text:}` hashes with no viewer branching in the
  view at all. This means for any game built on `_game_board_feed`, the per-viewer wording (e.g.
  hiding which card was drawn from the stock from everyone but the drawer) must be resolved inside
  the `TurnResult` object itself before it reaches the view — copying the Go Fish/Crazy Eights
  template-side-branching pattern would not work against the newer partial's contract.

## Testing gotchas

- `sign_in_as` (`spec/support/authentication_helpers.rb`) only swaps the session cookie — it does **not** reload the current page. In a system spec, calling it mid-test without a following `visit` means any subsequent interaction (clicking a link/button) still acts on markup rendered for the *previous* signed-in user. This has previously masked a real bug: a spec that switched users after the page had already rendered clicked a stale "Join" button meant for someone else, silently exercising a double-join code path instead of the scenario the test claimed to cover.
- Tag a system spec `:js` whenever the element under test is backed by a Stimulus controller, even if the spec only reads a server-rendered `data-*` attribute rather than anything the JS writes — it still proves the controller connects without erroring. That said, you don't need a `sleep`/wait for that kind of assertion: reading the attribute directly (`find('.timer')['data-timer-seconds-value']`) is instant, since it's server-rendered markup, not something JS has to compute first.
- This app aliases Capybara's `select` to a custom `smart_select` (`spec/support/helpers/select_helper.rb`) that resolves `from:` by **label text**, not element id/name — `select 'X', from: 'some_field_id'` fails with a confusing "unable to find label" error instead of selecting by id.
- `Game#can_start?` requires `players.size == game_size` **exactly**. A factory built with a `player_count:` transient but a mismatched (or default) `game_size:` makes `start!` **silently return `nil`** rather than raise — `game_state` stays nil with no obvious error pointing at the mismatch.
- Clicking a specific card in Rummy's overlapping fanned hand (`rummy_gameplay_spec.rb`) needs a `label.click()` JS dispatch (see the `check_hand_card` helper — `page.execute_script("...label[for='...'].click()")`), not a coordinate-based Capybara click. Chromium/Playwright's synthetic-mouse hit-testing intermittently reports a false "blocked by a different card" even when the real DOM geometry is correct (independently verified via `elementFromPoint`) — likely a hover-path quirk, not an actual visual-overlap bug. A `label.click()` still exercises real DOM click-activation semantics (toggles the checkbox, fires `change`), just without simulated mouse coordinates.

## Asset pipeline (Propshaft)

There is no `app/assets/stylesheets/app.css` and no `@import` chain tying the ~40 component
stylesheets under `app/assets/stylesheets/components/**` together — that's not a gap. `_head.html.slim`
calls `stylesheet_link_tag :app`, and `:app` is a built-in Propshaft symbol (not a literal asset name)
that bulk-includes every CSS file found under `app/assets/**/*.css`, each rendered as its own
individually fingerprinted `<link>` tag. Confirm this by inspecting a rendered `<head>` rather than
calling `stylesheet_path(:app)` directly — that singular helper does **not** carry the `:app`
special-casing (only `stylesheet_link_tag` does), so it raises `Propshaft::MissingAssetError` even
though the real page renders every component stylesheet correctly.

Optics' CSS bundle is pinned to a specific version on **jsdelivr** (`_head.html.slim`), but its
Lucide icon font (the `.li-*` classes) is a **separate webfont hosted on unpkg**, not bundled into
that CSS — confirmed by inspecting the CSS's `@font-face` rule. Precaching the whole font just to
get one icon working offline would pull down every icon in the set for nothing; `lucide-static`
publishes each icon as its own standalone SVG on unpkg instead (e.g.
`unpkg.com/lucide-static@<version>/icons/<name>.svg`), which is what the offline page precaches.
Also: an SVG's `stroke="currentColor"` does **not** resolve when the SVG is embedded via `<img>` —
`<img>` renders the SVG in an isolated document context, so `currentColor` falls back to the UA
default (effectively black) regardless of the page's theme. Theming such an icon for dark mode needs
CSS `filter: invert(1)` under `@media (prefers-color-scheme: dark)`, not `currentColor`.

Because every component stylesheet loads unconditionally on every page (no `@import` scoping), CSS
class names are effectively **global** — a BEM block name must be unique across the whole
`components/**` directory, not just within its own file. A real instance from the Rummy UI polish
(2026-07-22): `_game_board_game_over.html.slim`'s `<dialog>` reused the block name `game-over`,
already owned by Go Fish's non-modal inline win-screen (`game-over.css`'s
`.game-over { display: flex; }`). CSS's origin-based cascade means normal author rules always beat
the User-Agent stylesheet regardless of specificity, so that `display: flex` silently overrode the
browser's built-in `dialog:not([open]) { display: none }`, making the Rummy game-over dialog
permanently visible and breaking the whole board's layout/width. Fixed by renaming the block to
`game-board-over`. Grep a candidate class name across `components/**` before naming a new BEM block.

Every game's card-fan/overlap effect (`playing-card.css`/`card-collection.css`'s negative-margin
technique) depends on each card `<img>` being a **direct flex child** of `.card-collection` —
matching the shared `_card_collection.html.slim` partial's plain, unwrapped rendering. Rummy's hand
wraps each card in a `<label>` (for its selection checkbox), which silently broke the overlap (found
during a manual review, 2026-07-23): the negative margin landed on the `<img>` inside a normal
`display: inline-block` wrapper instead of on a flex-item sibling, shrinking and un-overlapping every
card. Fixed via `display: contents` on the wrapping `<label>` so its child `<img>` participates in
the flex layout directly, as if the label weren't there. Any future checkbox/label-wrapped card UI
needs the same treatment to keep this shared technique working.

`app/javascript/controllers/index.js` is **auto-generated** (per its own header comment) and does not
pick up a new controller file just by existing — a new `data-controller="foo"` in a view is silently
inert (no error, the controller simply never connects) until `bin/rails stimulus:manifest:update` is
run to add its `import`/`application.register(...)` lines. Hand-editing this file works too, but the
generator is the intended path and won't leave it out of sync. Forgetting this step looks exactly
like a morph/timing bug (attributes update, JS-driven behavior doesn't) — check that the controller
is actually registered before chasing a timing explanation.

## Background jobs and other supporting pieces

- **GoodJob** (Postgres-backed, no Redis) runs `ArchiveGameJob`, which marks any `Game` untouched for 2+ days as `archived_at` — there's no scheduled/cron wiring visible in this codebase, so check how/whether this job is currently enqueued before assuming it runs automatically.
- PWA/offline support: `app/javascript/controllers/service_worker_controller.js` registers a service worker via `rails/pwa`; `OfflineController` (Rails) and `offline_controller.js` (Stimulus) back the offline banner shown in `games/show`.
- `Country`/`State` are not `ActiveRecord` models — they're `Data.define` value objects backed by the `data_for` gem's static dataset (`config/countries.yml`), used for the user profile's country flag emoji and similar display-only concerns. `GameCatalog` reuses this same pattern for the in-app rules catalog (`config/games.yml`) — adding a new game's rules is a YAML entry, not a new controller/view.
