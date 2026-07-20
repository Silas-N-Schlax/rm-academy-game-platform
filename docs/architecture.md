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

## Turn form objects

Moves are **not** stored as their own database rows. Instead, `GoFishTurn` / `CrazyEightsTurn` are `ActiveModel`-based form objects (not `ActiveRecord`) that:

1. Take the submitted params plus `game` and `user` from `TurnsController#create`.
2. Validate the move (presence, whose turn it is, whether the move is legal given current game state) using each game's own validation rules.
3. On `save`, if valid, call `game.play(...)` with the right arguments for that game type, which mutates and re-persists `game_state`.

This exists specifically so each game type can define its own validation logic (Go Fish validates `player`/`rank`; Crazy Eights validates `rank`/`suit`/`wild_suit`/`request` and whose turn it is) while `TurnsController` stays a single, game-agnostic controller — it just calls `@game.turn_class.new(turn_params)`. This is also why `Game` requires subclasses to implement `turn_class`.

## Real-time updates

There's no bespoke `ActionCable` channel for gameplay. Instead:

- `Game` broadcasts via Turbo Streams: `after_create_commit`/`after_update_commit` call `broadcast_refresh_later_to "games"` (for lobby/list views) and `broadcast_refresh_later_to self` (for the individual game page).
- `Player` also broadcasts to `"games"` on create/update so the lobby list picks up seat changes.
- `app/views/games/show.html.slim` subscribes with `turbo_stream_from @game` and re-renders via `render @game`, which uses Rails' polymorphic partial lookup — `GoFishGame` renders `go_fish_games/_go_fish_game`, `CrazyEightsGame` renders `crazy_eights_games/_crazy_eights_game`.

## Background jobs and other supporting pieces

- **GoodJob** (Postgres-backed, no Redis) runs `ArchiveGameJob`, which marks any `Game` untouched for 2+ days as `archived_at` — there's no scheduled/cron wiring visible in this codebase, so check how/whether this job is currently enqueued before assuming it runs automatically.
- PWA/offline support: `app/javascript/controllers/service_worker_controller.js` registers a service worker via `rails/pwa`; `OfflineController` (Rails) and `offline_controller.js` (Stimulus) back the offline banner shown in `games/show`.
- `Country`/`State` are not `ActiveRecord` models — they're `Data.define` value objects backed by the `data_for` gem's static dataset (`config/countries.yml`), used for the user profile's country flag emoji and similar display-only concerns.
