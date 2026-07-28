# Architecture

## Core models and how they relate

```
User --< sessions (Session)
User --< players (Player) >-- Game
Game (STI base, type: "GoFishGame" | "CrazyEightsGame" | "RummyGame")
  has_many :players, dependent: :destroy
  has_many :users, through: :players
```

- `Game` is an STI base class (`type` column). `GoFishGame`, `CrazyEightsGame`, and `RummyGame` are the subclasses today; adding a new game means adding a new subclass plus a new engine namespace (see below), not touching the base class's schema. Per-type player-count bounds live as `#min_players`/`#max_players` methods on each subclass (not a hash on `Game`) — `Game` raises `NotImplementedError` by default, mirroring `engine_class`/`turn_class`/`play`/`valid_move?`/`presenter_class`, and `Game#valid_game_size` skips its check only when `self.class == Game`. `Game#valid_types` derives the full type list from `Game.descendants` (sorted alphabetically) rather than a hardcoded list — see the STI gotchas below for a real subtlety this introduces.
- `has_many :players`/`has_many :users` have no explicit `order`. Rails implicitly orders `.first`/`.last` by `id`, but `.map`/`.each`/`.to_a` do not — those can return rows in a different order under DB load. `GoFish::Game.create`/`CrazyEights::Game.create` learned this the hard way (players could get seated in the wrong turn order) and now `sort_by(&:id)` explicitly before mapping. `app/views/application/_go_fish_form.html.slim`'s player-select dropdown has the same latent gap and is not yet fixed — see `docs/roadmap.md`.
- `Player` is the join model between `User` and `Game` — one row per seat, holding `winner` (boolean/nil: `true` = won a finished game, `false` = lost a finished game, `nil` = the game hasn't finished yet). `Game#end_game` sets every non-winning player to `false` (not just leaving them `nil`) when a game ends — fixed 2026-07-27; before that, a non-winner was indistinguishable from a player in an unfinished game, which inflated loss/game counts in `Stat`. Games finished before that fix still have `nil` for their losers (no backfill migration was written — see `docs/roadmap.md`).
- `Session`/`Current` follow the standard Rails 8 authentication-generator pattern: a signed cookie holds a `session_id`, `Current.session` is set per-request in `Authentication` (a controller concern), and `Current.user` delegates to it.
- `Stat` (2026-07-28: migrated off a plain PORO, same pattern as `Leaderboard`) is now `Stat < ApplicationRecord` backed by a Scenic-managed Postgres view (`db/views/stats_v01.sql`, queried via `Stat.for(user)`), returning one row per game type the user has actually finished a game in, plus one rollup "overall" row (`type: nil`), via a single `GROUPING SETS ((players.user_id, games.type), (players.user_id))` query — collapses what used to be ~12 queries per stats-page load into 1. Two gotchas this surfaced: (1) the view's `type` column is treated as an STI discriminator by Rails unless the model sets `self.inheritance_column = nil` — any Scenic view with a literal `type` column needs the same guard; (2) an earlier draft joined via `LEFT JOIN games` (so a user's non-finished games would also match) which produced a spurious extra `type: nil` row whenever a user had unfinished-game participations — a `LEFT JOIN`'s unmatched row has `games.type = NULL`, and `GROUPING SETS` treats that as its own group, colliding with the real rollup row. Fixed by `JOIN`ing (not `LEFT JOIN`) restricted to finished games only — the real behavior change this brings: a user with zero finished games now returns **no rows at all**, not a zeroed row, so callers must handle an empty relation rather than assume a row always exists. Also needed a synthetic `ROW_NUMBER() OVER () AS id` primary key, since `user_id` repeats across a user's several rows and isn't unique the way `Leaderboard`'s one-row-per-user `id` is. A `StatsPresenter` sits in front of it, filling in a zeroed row for any game type in `Game.new.valid_types` that a user hasn't played, so the stats page always shows a row per known type without hardcoding the list. `Leaderboard`, meanwhile, is a separate `ActiveRecord` model backed by its own Scenic view (`db/views/leaderboards_v02.sql`, migrated via `create_view :leaderboards`). Editing an already-migrated view SQL file in place has **no effect on the live database**; to change a view's SQL, run `rails generate scenic:view <name>` to bump the version (creates a new `_vNN.sql` + an `update_view` migration), edit the new file, then migrate. The view computes a `rank` column via `ROW_NUMBER() OVER (ORDER BY total_wins DESC, total_games DESC, seconds_played DESC, win_percentage DESC, created_at ASC)` (2026-07-28) — one universal ranking, independent of whichever column the table is currently sorted/displayed by, since the tiebreak chain runs all the way down to `created_at` and fully resolves every tie (no two users ever share a rank). `Leaderboard.sorted_by(column)` deliberately mirrors this split: sorting by the default `total_wins` uses that exact same full chain (so its row order *is* rank order), while sorting by any other `SORT_COLUMNS` entry (`total_games`/`win_percentage`/`seconds_played`) ties break by name then `created_at` instead — a shorter, different chain. `win_percentage DESC` also needs `NULLS LAST` explicitly — Postgres sorts nulls *first* on a naive `DESC` order, which would put users with no finished games (nil `win_percentage`) ahead of users who'd actually won something. Pagination (Kaminari, 2026-07-28) was installed via `rolemodel-rails`'s `bin/rails generate rolemodel:kaminari` generator — the leaderboard is the first page in the app to use pagination, and this was the first time that generator had been run here. Its shipped templates call a `material_icon` helper that doesn't exist in this app (this app's icon library is Lucide, via `icon_helper.rb`'s `icon` method — see generator comment in that file) — `_first_page`/`_last_page`/`_next_page`/`_prev_page` needed `material_icon(...)` swapped for `icon(...)` calls to actually render. The `leaderboard-sort` Stimulus controller was renamed to `leaderboard-form` at the same time, since it's now shared by both the sort segmented-control and the new page-size segmented-control (it only ever does a generic "submit this form on change," never anything sort-specific).
- `Game.open_games` used to silently exclude any open game with **zero players** — it originally used `joins(:players)` (an INNER JOIN), which produces no row at all for a game with no matching `players` row. Changed to `includes(:players)` plus a correlated subquery so a zero-player open game is correctly included. This is a real behavior change: an existing system spec assumed only one open game would ever show a "Join" button and broke when a second (zero-player) one appeared — fixed by scoping the click to `dom_id(game)` rather than relying on there being just one match.

### STI gotchas

- `Game.descendants` only returns subclasses that have already been autoloaded into memory — confirmed empirically (`Game.descendants` returns `[]` before anything references a subclass). Test env doesn't eager-load by default (only `CI=true` does, per `config/environments/test.rb`), so a naive `Game.descendants` call could silently return an incomplete type list depending on what's already loaded in the process. Fixed via a memoized `Game.eager_load_subclasses!` (called from `valid_types`) that forces `Rails.application.eager_load!` once per process when not already eager-loading. Any other code that leans on `Game.descendants` needs the same guard.
- `Game.new(type: "GoFishGame", ...)` called on the **base** `Game` class immediately returns a `GoFishGame` instance, not a `Game` — this is standard Rails STI behavior, not a quirk, but it bit `app/views/games/new.html.slim`'s `simple_form_for @game`: with no explicit `as:` option, the form's param key is inferred from `@game.model_name.param_key`, which is `"game"` on the fresh `Game.new` from `GamesController#new` but `"go_fish_game"`/`"rummy_game"`/`"crazy_eights_game"` after a failed `create` re-renders `@game` as whatever subclass the submitted `type` resolved to. Resubmitting then posted params under the wrong key and `params.require(:game)` blew up. Fixed with `simple_form_for @game, as: "game", ...` to pin the param key regardless of STI subclass — any other STI-backed form needs the same explicit `as:`.

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
- `app/views/games/show.html.slim` subscribes with `turbo_stream_from @game` and re-renders via `render @game`, which uses Rails' polymorphic partial lookup — `GoFishGame` renders `go_fish_games/_go_fish_game`, `CrazyEightsGame` renders `crazy_eights_games/_crazy_eights_game`. `show.html.slim` builds one `@game.presenter_class.new(@game, current_user, turn:, turn_timer_seconds:)` and passes it down as the sole `presenter:` local — `Game#presenter_class` raises `NotImplementedError` by default, mirroring `engine_class`/`turn_class`. All three games now have a real presenter (`RummyPresenter`, `GoFishPresenter`, `CrazyEightsPresenter` — one file each under `app/presenters/`, same method-per-value shape) that the shared `_game_board*` partials call directly (`presenter.hand`, `presenter.opponents`, etc.) instead of reaching into a hash; `NullPresenter` (`app/presenters/null_presenter.rb`) is now dead code kept only as the `Game` base class's placeholder default. With three concrete presenters now in hand, the rule-of-three point for extracting a shared `GamePresenter` base class has been reached — it just hasn't been done yet, since no third presenter-touching feature has forced the question.
- The Go Fish turn timer (`timer_controller.js`) is a good example of a Turbo-morph gotcha: the countdown restarts from a dedicated Stimulus `anchor` value (`game.updated_at.to_f`), not from the remaining-seconds value itself. Morph only fires a Stimulus `valueChanged` callback when the attribute **string** actually changes on re-render — on a go-again turn the recomputed remaining-seconds can coincidentally match the prior render's value, which would silently fail to reset the countdown if that value were the restart trigger. `GoFishGame#remaining_turn_seconds` also assumes `updated_at` marks turn-start (true today because only `start!`/`play`/`end_game` write the `games` row mid-game) — a future `touch:` association or incidental `game.update` elsewhere would silently desync the timer.
- A related but distinct morph gotcha: Idiomorph (the library behind `turbo-refresh-method: morph`, enabled in `_head.html.slim`) matches old/new DOM nodes **by `id`** and, when it finds a match on a form element, preserves that element's *live* value/checked state rather than overwriting it with the freshly-rendered HTML. This means in-progress client-side state (e.g. a checked-but-unsubmitted checkbox) can survive an unrelated `broadcast_refresh_later_to` refresh — but only if the element has a stable, unique `id` for Idiomorph to match against. Any interactive multi-select UI built on top of the broadcast-refresh loop needs stable ids on its inputs, or a background refresh can silently reset a player's in-progress selection. Because morph preserves the underlying input state but doesn't re-fire a `change` event, code that derives visual state (CSS classes, button enablement) from those inputs should re-sync on the `turbo:morph` document event, not rely solely on `change` listeners.
- `finished_at` is only set as a **side effect of `Game#play`/`end_game`**, not automatically whenever `winner?` becomes true. Code (including specs) that mutates `game_state` directly into a winning state without going through `play` will have `finished_at` still `nil` — anything reading it (e.g. the game-over display) must not assume it's set just because `winner?` is true.
- **A same-page form-submit redirect is also a morph, and it's asynchronous.** When a Turbo-intercepted form POST redirects back to the page it was submitted from (e.g. `TurnsController#create`'s `redirect_to game_path(@game)`), Turbo Drive treats the resulting GET as a same-page visit and applies `turbo-refresh-method: morph` — it does **not** behave like a synchronous full reload. A system spec that immediately follows one form interaction with another (check a box, then click a button) can race ahead of the morph settling, silently losing form state (e.g. `card_ids` missing from the next POST) with no error raised — found while building Rummy's lay-off/meld system specs, several of which were intermittently flaky until each `:js` spec asserted on the settled post-morph state (e.g. an updated hand card count) before its next interaction. This is a distinct gotcha from the stable-id/Idiomorph one above — that one is about *what* gets preserved across a morph; this one is about *timing* between a morph-triggering navigation and whatever the test does next.
- **All three games now share one feed-rendering contract.** Every game renders turn-by-turn
  history through the shared `_game_board_feed.html.slim`, which takes each presenter's `feed`
  array of already-resolved `{actor:, time:, lines: [{text:, kind:}]}` hashes with **no viewer
  branching in the view at all** — each `TurnResult` resolves per-viewer wording itself via
  `feed_lines(viewer_id)`/`actor_label(viewer_id)` (e.g. hiding which card was drawn from the stock
  from everyone but the drawer), called with `current_user.id` from the presenter before the data
  ever reaches the template. A future new game must implement these two methods on its own
  `TurnResult` and feed the shared partial the same way — there is no per-game feed partial to fall
  back on anymore (Go Fish's and Crazy Eights' original ones were deleted once each migrated).
- **Any reuse of `TurnResult#feed_lines`/`#actor_label` must pass `current_user.id` as the viewer,
  never the acting player's own id.** `RummyPresenter#last_action_for` (the per-opponent "last
  action" summary in the player-list panel) finds an opponent's most recent `TurnResult` and calls
  `feed_lines(current_user.id)` on it — passing the opponent's own id instead would incorrectly
  reveal which card they drew from the stock, since `feed_lines` only shows that detail when
  `actor?(viewer_id)` is true for the *viewer*, not the actor.

## Testing gotchas

- `sign_in_as` (`spec/support/authentication_helpers.rb`) only swaps the session cookie — it does **not** reload the current page. In a system spec, calling it mid-test without a following `visit` means any subsequent interaction (clicking a link/button) still acts on markup rendered for the *previous* signed-in user. This has previously masked a real bug: a spec that switched users after the page had already rendered clicked a stale "Join" button meant for someone else, silently exercising a double-join code path instead of the scenario the test claimed to cover.
- Tag a system spec `:js` whenever the element under test is backed by a Stimulus controller, even if the spec only reads a server-rendered `data-*` attribute rather than anything the JS writes — it still proves the controller connects without erroring. That said, you don't need a `sleep`/wait for that kind of assertion: reading the attribute directly (`find('.timer')['data-timer-seconds-value']`) is instant, since it's server-rendered markup, not something JS has to compute first.
- This app aliases Capybara's `select` to a custom `smart_select` (`spec/support/helpers/select_helper.rb`) that resolves `from:` by **label text**, not element id/name — `select 'X', from: 'some_field_id'` fails with a confusing "unable to find label" error instead of selecting by id.
- `Game#can_start?` requires `players.size == game_size` **exactly**. A factory built with a `player_count:` transient but a mismatched (or default) `game_size:` makes `start!` **silently return `nil`** rather than raise — `game_state` stays nil with no obvious error pointing at the mismatch.
- Clicking a specific card in Rummy's overlapping fanned hand (`rummy_gameplay_spec.rb`) needs a `label.click()` JS dispatch (see the `check_hand_card` helper — `page.execute_script("...label[for='...'].click()")`), not a coordinate-based Capybara click. Chromium/Playwright's synthetic-mouse hit-testing intermittently reports a false "blocked by a different card" even when the real DOM geometry is correct (independently verified via `elementFromPoint`) — likely a hover-path quirk, not an actual visual-overlap bug. A `label.click()` still exercises real DOM click-activation semantics (toggles the checkbox, fires `change`), just without simulated mouse coordinates.
- Asserting a CSS state that's gated by a `transition-delay` (e.g. the Optics tooltip reveal — see Asset pipeline below) needs to **poll** (`wait_until` from `capybara_helper.rb`), not read `getComputedStyle` synchronously right after the triggering action. A synchronous read can catch the *stale* pre-transition value even when the underlying rule is correct — and the inverse is more dangerous: a spec that only asserts `.matches_css?(':focus-visible')` without also checking the actual visual effect (opacity/visibility) will pass even if the CSS rule producing that effect is completely missing, silently defeating the point of the test.

## Asset pipeline (Propshaft)

There is no `app/assets/stylesheets/app.css` and no `@import` chain tying the ~40 component
stylesheets under `app/assets/stylesheets/components/**` together — that's not a gap. `_head.html.slim`
calls `stylesheet_link_tag :app`, and `:app` is a built-in Propshaft symbol (not a literal asset name)
that bulk-includes every CSS file found under `app/assets/**/*.css`, each rendered as its own
individually fingerprinted `<link>` tag. Confirm this by inspecting a rendered `<head>` rather than
calling `stylesheet_path(:app)` directly — that singular helper does **not** carry the `:app`
special-casing (only `stylesheet_link_tag` does), so it raises `Propshaft::MissingAssetError` even
though the real page renders every component stylesheet correctly.

`@rolemodel/optics` ships CSS and design tokens only — no JS runtime (confirmed by inspecting
`node_modules/@rolemodel/optics`: `css/` and `tokens/` directories, nothing executable). Any
interactive behavior behind an Optics class (a modal opening, a tab switching, a drawer sliding
out) has to be wired up by this app's own Stimulus controllers — Optics itself doesn't provide it.

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

A related nesting mistake (leaderboard pagination, 2026-07-28): `.leaderboard__sort` and
`.leaderboard__pagination` are **siblings** of `.leaderboard` (the `<table>`) in the markup, not
descendants of it. A media-query override nested as `.leaderboard { @media (...) { .leaderboard__
sort { ... } } }` compiles to the descendant selector `.leaderboard .leaderboard__sort`, which can
never match anything — the rule silently does nothing, no error, no warning. CSS nesting only pays
off when the nested selector's real DOM position matches the nesting; check the markup's actual
parent/child relationship before nesting a rule, not just which block it's conceptually "part of."

Every game's card-fan/overlap effect (`playing-card.css`/`card-collection.css`'s negative-margin
technique) depends on each card `<img>` being a **direct flex child** of `.card-collection` —
matching the shared `_card_collection.html.slim` partial's plain, unwrapped rendering. Rummy's hand
wraps each card in a `<label>` (for its selection checkbox), which silently broke the overlap (found
during a manual review, 2026-07-23): the negative margin landed on the `<img>` inside a normal
`display: inline-block` wrapper instead of on a flex-item sibling, shrinking and un-overlapping every
card. Fixed via `display: contents` on the wrapping `<label>` so its child `<img>` participates in
the flex layout directly, as if the label weren't there. Any future checkbox/label-wrapped card UI
needs the same treatment to keep this shared technique working.

Optics' `[data-tooltip-text]` component only reveals on `:hover` by default — unreachable on touch
or via keyboard. `theme.css` adds a `[data-tooltip-text]:focus-visible` rule (opacity/visibility,
mirroring Optics' own `:hover` rule) so every tooltip in the app — not just a specific one — is also
reachable by tapping/tabbing to it. Two things to know if you touch this: the reveal is gated by
Optics' `--op-transition-tooltip` token, which has a **300ms delay before its 300ms fade even
starts** — a system spec asserting the reveal must wait past that (see Testing gotchas above), not
read `getComputedStyle` synchronously. And Optics' `.table` component sets `contain: paint`, which
**clips** any cell content that overflows the table's own outer box — relevant for any column with
unbounded-length content (e.g. an ever-growing duration string); the fix is `overflow-wrap: anywhere`
scoped to just the affected columns (not the whole row, or a player name column will break
mid-word), letting long content wrap onto a second line instead of clipping at the table edge or
bleeding into a neighboring cell.

Applying `display: flex` **directly to a `<td>`** breaks its normal row-height-stretch behavior in a
`border-collapse: separate` table (found building the leaderboard, 2026-07-27): the flexed cell
sizes to its own content height instead of matching its taller siblings, leaving a visible seam
where its short background/border ends before the row's actual bottom edge. Keep the flex layout on
a child element inside the cell, never the `<td>` itself.

Converting a table into stacked mobile "cards" (`stats-ledger`'s `@media` block, 2026-07-28) needs
the gap between cards created by margin on the **row** element itself, not on its last child. A
child's `margin-block-end` only escapes its parent's own background box if the parent has no
bottom padding/border to block the collapse — once the row has its own `padding-block` (for
internal breathing room, as `.stats-ledger__row` does), that collapse can't happen, so a margin on
the row's last cell just adds more space still painted in the row's own background color,
visually indistinguishable from padding rather than a true gap revealing what's behind it.
Confirmed by sampling the rendered page's raw pixel colors: moving the margin from `td:last-child`
to `tr:not(:last-child)` was what actually revealed the surrounding `.stats-ledger` background
between cards.

A CSS Grid item needs an explicit `min-height: 0` (or `min-width: 0` for row-direction tracks) to
actually respect a `1fr` track size — a grid item's default `min-height` is `auto`, meaning it
refuses to shrink below its own content's intrinsic size even when that's taller than the track it
was allotted, so the content silently blows out past the grid container's own boundary instead of
being constrained or scrolling. Found in `components/game-table.css`'s `.game-table__center`
(2026-07-25): on a short viewport, its content (Crazy Eights' draw/discard piles plus the wild-suit
badge) overflowed past `.game-table`'s bottom edge by tens of pixels, landing directly against the
hand footer with zero visible gap and sometimes pushing the wild-suit badge out of view entirely.
Fixed with `min-height: 0` plus `justify-content: safe center` (degrades to top-aligned instead of
overflowing symmetrically top-and-bottom when content doesn't fit) and a guaranteed `padding-bottom`.
Any future grid layout with a `1fr`/`auto` mix and variable-height content needs the same
`min-height: 0` guard, or a short viewport can reproduce this exact silent overflow.

Overriding a vendor Optics rule that's written as **nested** CSS requires nesting your own override
the same way, or it silently loses on specificity regardless of file load order (found fixing the
mobile bottom-navbar overlap, 2026-07-28): `optics-overrides/op-page.css` had
`.op-page { .op-page__sidebar {...} }` correctly nested, but a new `.op-page__main {...}` rule was
added as a **sibling** of `.op-page { }` instead of nested inside it — compiling to the flat selector
`.op-page__main` (specificity 0,1,0) instead of `.op-page .op-page__main` (0,2,0). The vendor's own
nested `.op-page .op-page__main { display: grid; ... }` rule kept winning regardless of `display:
block` being declared later in a later-loaded stylesheet, because higher specificity always beats
source order. `getComputedStyle` kept reporting the override's value for properties the vendor rule
never explicitly set (e.g. `align-items`, no real contest there) which made the real cause — the
missing nesting — look unrelated for a while.

Related, same investigation: `display: grid` + `overflow: auto` on a container whose grid item's
content overflows its track does **not** reliably extend that container's own `scrollHeight` via a
trailing `padding-bottom`, in this rendering engine — confirmed by comparing identical padding
values on `display:grid` vs `display:flex`/`block` ancestors of the same overflowing content, with
the grid version consistently coming up ~116px short regardless of where in the ancestor chain the
padding was placed. Switching the container from `display: grid` to `display: block` (this app
doesn't use `.op-page__main`'s vendor-provided header/content/footer grid areas anyway) fixed it.
This is why the fixed-mobile-navbar-clears-scrolled-content padding lives directly on
`.op-page__main` — global, not a per-page `.page`/`.page__content` workaround.

SimpleForm's `CollectionRadioButtonsInput` (the base class behind `SegmentedControlInput`) takes
`checked:` to preselect an option, not `selected:` — `selected:` is a `collection_select`-only
option and fails **silently** on a radio collection (no error, the option just never renders
checked). Cost real time on the leaderboard's sort control before the fix was found by reading
Rails' `collection_radio_buttons` source directly.

`app/javascript/controllers/index.js` is **auto-generated** (per its own header comment) and does not
pick up a new controller file just by existing — a new `data-controller="foo"` in a view is silently
inert (no error, the controller simply never connects) until `bin/rails stimulus:manifest:update` is
run to add its `import`/`application.register(...)` lines. Hand-editing this file works too, but the
generator is the intended path and won't leave it out of sync. Forgetting this step looks exactly
like a morph/timing bug (attributes update, JS-driven behavior doesn't) — check that the controller
is actually registered before chasing a timing explanation.

A per-game Stimulus controller's filename determines its registered identifier via a mechanical
underscore-to-dash translation (`stimulus:manifest:update` does this, not the developer), so a
compound game name needs its internal underscore **dropped** from the filename to land on the short
identifier the existing convention uses: `gofish_turn_controller.js` → `gofish-turn`,
`crazyeights_turn_controller.js` → `crazyeights-turn` — not `crazy_eights_turn_controller.js` →
`crazy-eights-turn`, which is what the mechanical translation would otherwise produce from the
"natural" filename. Get this wrong and a view's `data-controller`/`data-action` written against the
short form silently never connects — the same silent-failure shape as forgetting to regenerate the
manifest at all, but caused by a filename/identifier mismatch instead.

## Background jobs and other supporting pieces

- **GoodJob** (Postgres-backed, no Redis) runs `ArchiveGameJob`, which marks any `Game` untouched for 2+ days as `archived_at` — there's no scheduled/cron wiring visible in this codebase, so check how/whether this job is currently enqueued before assuming it runs automatically.
- PWA/offline support: `app/javascript/controllers/service_worker_controller.js` registers a service worker via `rails/pwa`; `OfflineController` (Rails) and `offline_controller.js` (Stimulus) back the offline banner shown in `games/show`.
- `Country`/`State` are not `ActiveRecord` models — they're `Data.define` value objects backed by the `data_for` gem's static dataset (`config/countries.yml`), used for the user profile's country flag emoji and similar display-only concerns. `GameCatalog` reuses this same pattern for the in-app rules catalog (`config/games.yml`) — adding a new game's rules is a YAML entry, not a new controller/view.
