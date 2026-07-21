# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, etc.) when working with code in this repository.

## What this is

A Rails web app where people play classic card games online with friends, family, or strangers — currently Go Fish and Crazy Eights, with more games planned. It's a RoleModel Software Academy learning project: a sandbox for practicing real-app patterns (Rails, Hotwire, TDD) before joining production client work. It also doubles as something genuinely playable to show non-developer friends and family.

## Tech stack

- **Ruby on Rails 8.1**, PostgreSQL (`jsonb` for serialized game state)
- **Hotwire**: Turbo (Streams/Frames) + Stimulus — no SPA framework, no custom ActionCable channels (see [docs/architecture.md](docs/architecture.md))
- **Slim** templates, **simple_form**, `rolemodel-rails` house gem
- **esbuild** bundles `app/javascript`; **GoodJob** runs background jobs (Postgres-backed, no Redis)
- **RSpec** + FactoryBot + Capybara (Playwright driver) for tests

## Running the app

- `bin/setup` — install deps, prepare DB, start dev server
- `bin/dev` — runs web (Puma), `yarn build --watch`, and the GoodJob worker (see `Procfile.dev`)
- `bin/rails console` / `bin/rails db:prepare`

## Testing

- Run the whole suite: `bundle exec rspec`
- Run one file: `bundle exec rspec spec/models/go_fish/game_spec.rb`
- Run one example: `bundle exec rspec spec/models/go_fish/game_spec.rb:42`
- System specs (`spec/system`) drive a real browser via Capybara + Playwright; can run headed or headless.
- **TDD is required here — do not write implementation code before a failing spec.**

## Linting / CI checks

- `bin/rubocop` (Omakase Rails style, config in `.rubocop.yml`)
- `bin/brakeman`, `bin/bundler-audit`, `bin/importmap audit` — security/static analysis, run via `bin/ci`
- `bin/ci` does **not** run RSpec — always run the test suite yourself before considering work done

## Architecture in brief

Each game type is an STI subclass of `Game` (`GoFishGame`, `CrazyEightsGame`) that serializes its entire live game state as a plain Ruby object (`GoFish::Game` / `CrazyEights::Game`) into a `jsonb` column via a custom `ActiveModel`-style coder (`self.dump`/`self.load`/`as_json`/`from_json`). Moves are validated and applied through non-persisted `ActiveModel` form objects (`GoFishTurn`/`CrazyEightsTurn`) rather than a `turns` database table — this exists specifically so each game type can define its own move validations while sharing one `TurnsController`/routing shape. Real-time updates use Turbo Stream broadcasts (`broadcast_refresh_later_to`), not bespoke ActionCable channels. Full details, including why this shape was chosen: [docs/architecture.md](docs/architecture.md).

Game rules (including deliberate deviations from traditional in-person rules to make online play work) are the single biggest thing that will surprise a newcomer — see [docs/go_fish_rules.md](docs/go_fish_rules.md) and [docs/crazy_eights_rules.md](docs/crazy_eights_rules.md) before touching either game engine.

## Conventions (not enforced by Rubocop — enforce these yourself)

- **No method/block body over 7 lines**, not counting the signature line and `end`.
- **No bare instance variables** outside of controllers, views (Slim templates), initializers, and lazy-init memoization (`@foo ||= ...`). Everywhere else, expose state through `attr_accessor`/`attr_reader` and call it via `self.`.
- **No magic numbers, strings, or regexes** — pull them into a well-named constant, or a well-named local/instance variable if scope doesn't warrant a constant. Look at existing code (e.g. `GoFish::Card::RANKS`, `CrazyEights::Game::SMALL_GAME_MAX_SIZE`) for the expected style. This is a judgment call, not a rule to apply to every literal — only extract a constant when a literal's meaning genuinely isn't clear from its surrounding context (e.g. a bare number repeated in multiple places, or one with no obvious relation to the code around it). A literal like dividing by `3600` inside a method explicitly about formatting elapsed time doesn't need `SECONDS_PER_HOUR` pulled out just because it's a number.
- **TDD always** — write the failing spec first.
- **Skinny controllers, fat models** — business logic belongs in models/game engines, not controllers.
- **Validation errors not tied to one specific attribute** (e.g. an invalid move in `GoFishTurn`/`CrazyEightsTurn`) should use `errors.add(:base, "message")`, not `errors.add("message")` — the latter treats the message string itself as the attribute name.
- **CSS/Slim structure**: use BEM (`block__element--modifier`) as much as possible for class naming. Prefer `@rolemodel/optics` (already a dependency, see `package.json`/`app/assets/stylesheets/components/optics-overrides`) for values (colors, spacing, etc.) and built-in components wherever it fits, instead of hand-rolled one-off CSS.
- `znotes/` is where the project owner stores plans and files that don't need to be committed (gitignored via a global gitignore, not this repo's `.gitignore`).

## Key context

- [docs/architecture.md](docs/architecture.md) — model relationships, the serialized game-state pattern, Turn form objects, real-time updates, auth/session model
- [docs/go_fish_rules.md](docs/go_fish_rules.md) — Go Fish rules as implemented here (matches the in-app rules page)
- [docs/crazy_eights_rules.md](docs/crazy_eights_rules.md) — Crazy Eights rules as implemented here, including online-specific rule changes and edge cases (no in-app rules page exists yet)
