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

Game rules (including deliberate deviations from traditional in-person rules to make online play work) are the single biggest thing that will surprise a newcomer — see [docs/go_fish_rules.md](docs/go_fish_rules.md), [docs/crazy_eights_rules.md](docs/crazy_eights_rules.md), and [docs/rummy_rules.md](docs/rummy_rules.md) before touching any game engine.

## Conventions (not enforced by Rubocop — enforce these yourself)

- **No method/block body over 7 lines**, not counting the signature line and `end`.
- **No bare instance variables** outside of controllers, views (Slim templates), initializers, and lazy-init memoization (`@foo ||= ...`). Everywhere else, expose state through `attr_accessor`/`attr_reader` and call it via `self.`.
- **No magic numbers, strings, or regexes** — pull them into a well-named constant, or a well-named local/instance variable if scope doesn't warrant a constant. Look at existing code (e.g. `GoFish::Card::RANKS`, `CrazyEights::Game::SMALL_GAME_MAX_SIZE`) for the expected style. This is a judgment call, not a rule to apply to every literal — only extract a constant when a literal's meaning genuinely isn't clear from its surrounding context (e.g. a bare number repeated in multiple places, or one with no obvious relation to the code around it). A literal like dividing by `3600` inside a method explicitly about formatting elapsed time doesn't need `SECONDS_PER_HOUR` pulled out just because it's a number.
- **TDD always** — write the failing spec first.
- **Skinny controllers, fat models** — business logic belongs in models/game engines, not controllers.
- **Never more than one instance variable in a controller action.** If a second piece of state needs to reach the view (e.g. a non-persisted record whose validation errors should render), pass it via `render ..., locals: { ... }` instead — and thread that local through any partials it needs to reach with `local_assigns[:name]`, since locals don't auto-propagate into nested `render partial:` calls.
- **Validation errors not tied to one specific attribute** (e.g. an invalid move in `GoFishTurn`/`CrazyEightsTurn`) should use `errors.add(:base, "message")`, not `errors.add("message")` — the latter treats the message string itself as the attribute name.
- **CSS/Slim structure**: use BEM (`block__element--modifier`) as much as possible for class naming. Prefer `@rolemodel/optics` (already a dependency, see `package.json`/`app/assets/stylesheets/components/optics-overrides`) for values (colors, spacing, etc.) and built-in components wherever it fits, instead of hand-rolled one-off CSS. For a custom size with no matching spacing token, use `calc(var(--op-size-unit) * n)` rather than a hard-coded px value (see `panel.css`) — `n` should always be a whole number (never a decimal), and the `calc()` should always have a trailing `/* Npx */` comment with the resulting pixel value.
- **CSS file ownership**: a rule that targets a given block's class always lives in that block's own stylesheet file — even a compound-selector rule that only applies in combination with another block's modifier (e.g. `.playing-card.game-board__meld-card` belongs in `playing-card.css`, not `game-board.css`).
- **BEM block names must be unique project-wide**, not just within the file you're editing — there's no CSS scoping between component stylesheets (see [docs/architecture.md](docs/architecture.md)'s Asset Pipeline section: every file under `components/**` loads on every page), so two blocks sharing a name can silently collide, even overriding browser defaults like a `<dialog>`'s hidden-by-default state.
- **Full-viewport game-board shells** (e.g. `.gf-game`, `.game-board`) need `overflow: hidden` (fallback) followed by `overflow: clip` on both `html` and `body` to fully lock page scroll — `hidden` alone still permits touch-drag/programmatic scroll into off-screen content in some browsers.
- `znotes/` is where the project owner stores plans and files that don't need to be committed (gitignored via a global gitignore, not this repo's `.gitignore`).

## Key context

- [docs/architecture.md](docs/architecture.md) — model relationships, the serialized game-state pattern, Turn form objects, real-time updates, auth/session model
- [docs/go_fish_rules.md](docs/go_fish_rules.md) — Go Fish rules as implemented here (matches the in-app rules page)
- [docs/crazy_eights_rules.md](docs/crazy_eights_rules.md) — Crazy Eights rules as implemented here, including online-specific rule changes and edge cases
- [docs/rummy_rules.md](docs/rummy_rules.md) — Rummy rules as implemented here (engine not yet built — see `docs/roadmap.md`)
