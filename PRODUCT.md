# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Friends, family, and (eventually) strangers who want to play classic card games online together — not developers, not necessarily tech-savvy. Real accounts (email/password), not anonymous play. The product is designed and judged as a genuinely usable, fun experience for these players first; that it also exists as a RoleModel Software Academy learning project (a sandbox for practicing Rails/Hotwire/TDD patterns) explains why it was built this way but is not what design decisions should optimize for.

## Product Purpose

Lets a small group of people who know each other start or join a quick, casual card game session (roughly 15–30 minutes) without needing to be in the same room. Success looks like: a player can get from the lobby into an active game with almost no friction, and the game itself is easy to follow turn-to-turn without prior familiarity with the app.

## Positioning

Undecided/open — no confirmed differentiator beyond "plays classic card games (Go Fish, Crazy Eights, Rummy in progress) online with people you actually know." Not positioned as a competitive/stats-driven platform or a place to match with strangers, though win/loss stats exist as a feature.

## Operating Context

- Lobby (`root "games#index"`) shows "Your Games" (in progress) and "Open Games" (joinable) — this is the home screen for a returning player.
- Starting a game: create a new game, others join as players/seats before it begins.
- Playing a game: turn-based moves submitted one at a time (`turns#create`), real-time updates pushed to all players via Turbo Streams.
- In-app rules pages per game (`rules#index`/`#show`), sourced from `config/games.yml` — written for a non-developer audience learning the game's rules for the first time.
- Game history and per-user stats (win/loss, averages) are available but secondary to actively playing.
- PWA-installable with an offline banner/page — implies some players may use it like an installed app, including on mobile, with graceful handling when connectivity drops.

## Capabilities and Constraints

- Games implemented: Go Fish, Crazy Eights. Rummy rules are documented (`docs/rummy_rules.md`) but the engine is not yet built — an in-progress `/board_preview` route exists only to preview the new game-board UI against hardcoded mock data and is expected to be deleted once Rummy ships.
- Real-time sync uses Turbo Stream broadcasts, not custom ActionCable channels — an architectural constraint, not just an implementation detail.
- No dedicated accessibility tooling (no axe/a11y linter in the Gemfile) and only scattered `aria-label` usage so far — accessibility is not yet a confirmed formal requirement, just ad hoc.

## Brand Commitments

None fixed yet. Page title is the literal placeholder "Game Platform" and the login logo is a generic "go fish game logo" placeholder image — both are known-temporary and should not be treated as an intentional brand identity. Do not invent a product name, logo, or voice; treat naming/branding as an open decision.

## Evidence on Hand

- Real, playable Go Fish and Crazy Eights game engines with real rules pages (`docs/go_fish_rules.md`, `docs/crazy_eights_rules.md`) — these reflect actual implemented behavior, including deliberate deviations from in-person rules for online play, and should be treated as ground truth for those games.
- Rummy: rules are finalized (`docs/rummy_rules.md`) and UI mockups exist (`znotes/rummy/`, approved through v7 per `docs/roadmap.md`), but there is no working engine yet — don't imply Rummy is playable in any user-facing copy.
- No testimonials, press, case studies, or real usage data exist; none should be fabricated.

## Product Principles

- Optimize for the person playing a casual game with people they know, not for a developer/reviewer audience or for strangers matchmaking.
- Low friction from lobby to active game; the game board should be followable without needing the rules page open, though rules are always one click away for newcomers.
- Real-time state (whose turn it is, what changed) should be obvious without a page refresh, per the Turbo Streams architecture.
- Don't design around an assumed brand identity — "Game Platform" and its placeholder assets are provisional, not a locked-in look.
- Each game (Go Fish, Crazy Eights, and eventually Rummy) should feel like the same product, not three disconnected mini-apps — shared lobby, shared rules-page pattern, shared game-board conventions.

## Accessibility & Inclusion

No confirmed product-specific accessibility standard has been established yet; treat as an open gap rather than a settled requirement.
