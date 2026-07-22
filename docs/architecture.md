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

## Real-time updates

There's no bespoke `ActionCable` channel for gameplay. Instead:

- `Game` broadcasts via Turbo Streams: `after_create_commit`/`after_update_commit` call `broadcast_refresh_later_to "games"` (for lobby/list views) and `broadcast_refresh_later_to self` (for the individual game page).
- `Player` also broadcasts to `"games"` on create/update so the lobby list picks up seat changes.
- `app/views/games/show.html.slim` subscribes with `turbo_stream_from @game` and re-renders via `render @game`, which uses Rails' polymorphic partial lookup — `GoFishGame` renders `go_fish_games/_go_fish_game`, `CrazyEightsGame` renders `crazy_eights_games/_crazy_eights_game`.
- The Go Fish turn timer (`timer_controller.js`) is a good example of a Turbo-morph gotcha: the countdown restarts from a dedicated Stimulus `anchor` value (`game.updated_at.to_f`), not from the remaining-seconds value itself. Morph only fires a Stimulus `valueChanged` callback when the attribute **string** actually changes on re-render — on a go-again turn the recomputed remaining-seconds can coincidentally match the prior render's value, which would silently fail to reset the countdown if that value were the restart trigger. `GoFishGame#remaining_turn_seconds` also assumes `updated_at` marks turn-start (true today because only `start!`/`play`/`end_game` write the `games` row mid-game) — a future `touch:` association or incidental `game.update` elsewhere would silently desync the timer.
- `finished_at` is only set as a **side effect of `Game#play`/`end_game`**, not automatically whenever `winner?` becomes true. Code (including specs) that mutates `game_state` directly into a winning state without going through `play` will have `finished_at` still `nil` — anything reading it (e.g. the game-over display) must not assume it's set just because `winner?` is true.

## Testing gotchas

- `sign_in_as` (`spec/support/authentication_helpers.rb`) only swaps the session cookie — it does **not** reload the current page. In a system spec, calling it mid-test without a following `visit` means any subsequent interaction (clicking a link/button) still acts on markup rendered for the *previous* signed-in user. This has previously masked a real bug: a spec that switched users after the page had already rendered clicked a stale "Join" button meant for someone else, silently exercising a double-join code path instead of the scenario the test claimed to cover.
- Tag a system spec `:js` whenever the element under test is backed by a Stimulus controller, even if the spec only reads a server-rendered `data-*` attribute rather than anything the JS writes — it still proves the controller connects without erroring. That said, you don't need a `sleep`/wait for that kind of assertion: reading the attribute directly (`find('.timer')['data-timer-seconds-value']`) is instant, since it's server-rendered markup, not something JS has to compute first.
- This app aliases Capybara's `select` to a custom `smart_select` (`spec/support/helpers/select_helper.rb`) that resolves `from:` by **label text**, not element id/name — `select 'X', from: 'some_field_id'` fails with a confusing "unable to find label" error instead of selecting by id.
- `Game#can_start?` requires `players.size == game_size` **exactly**. A factory built with a `player_count:` transient but a mismatched (or default) `game_size:` makes `start!` **silently return `nil`** rather than raise — `game_state` stays nil with no obvious error pointing at the mismatch.

## Asset pipeline (Propshaft)

There is no `app/assets/stylesheets/app.css` and no `@import` chain tying the ~40 component
stylesheets under `app/assets/stylesheets/components/**` together — that's not a gap. `_head.html.slim`
calls `stylesheet_link_tag :app`, and `:app` is a built-in Propshaft symbol (not a literal asset name)
that bulk-includes every CSS file found under `app/assets/**/*.css`, each rendered as its own
individually fingerprinted `<link>` tag. Confirm this by inspecting a rendered `<head>` rather than
calling `stylesheet_path(:app)` directly — that singular helper does **not** carry the `:app`
special-casing (only `stylesheet_link_tag` does), so it raises `Propshaft::MissingAssetError` even
though the real page renders every component stylesheet correctly.

## Background jobs and other supporting pieces

- **GoodJob** (Postgres-backed, no Redis) runs `ArchiveGameJob`, which marks any `Game` untouched for 2+ days as `archived_at` — there's no scheduled/cron wiring visible in this codebase, so check how/whether this job is currently enqueued before assuming it runs automatically.
- PWA/offline support: `app/javascript/controllers/service_worker_controller.js` registers a service worker via `rails/pwa`; `OfflineController` (Rails) and `offline_controller.js` (Stimulus) back the offline banner shown in `games/show`.
- `Country`/`State` are not `ActiveRecord` models — they're `Data.define` value objects backed by the `data_for` gem's static dataset (`config/countries.yml`), used for the user profile's country flag emoji and similar display-only concerns. `GameCatalog` reuses this same pattern for the in-app rules catalog (`config/games.yml`) — adding a new game's rules is a YAML entry, not a new controller/view.
