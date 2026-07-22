# Feature: Card 4a — Extract shared `Card` + engine dedup (no behavior change)

Source plan: `znotes/plans/card-4a-extract-shared-card-engine-brave.md`.

## Status (2026-07-21): superseded by a Part 1 / Part 2 split — see the source plan's Status section

This doc was written before the card was split by risk. **What actually shipped as Part 1** differs
from what's below: `CardGame::Card` + `CardGame::Pile` + `CardGame::Deck` (Pile/Deck weren't in this
doc's original scope at all — added because `CrazyEights::Pile` already existed and `GoFish::Deck`
duplicated its surface inline). Actual specs used:
`spec/support/shared_examples/card_game_card_examples.rb`,
`spec/support/shared_examples/card_game_pile_examples.rb`,
`spec/support/shared_examples/card_game_deck_examples.rb` — all in `spec/support/shared_examples/`,
not `spec/models/support/` as drafted below. All Part 1 items in this doc are done and green.

**Everything below under `CardGame::Engine`/`app/models/card_game/engine.rb`/the `start!` hoist is
Part 2 — not started.** It remains an accurate forward-looking spec plan for that follow-up; re-read
it fresh when Part 2 is planned rather than trusting the checkboxes below (they were never checked
off during Part 1 since Part 1 didn't touch this scope).

## Feature summary

Pure refactor, no behavior change. Introduce `CardGame::Card` and `CardGame::Engine` base
classes that `GoFish::Card`/`CrazyEights::Card` and `GoFish::Game`/`CrazyEights::Game` inherit
from, deduplicating the genuinely-identical surface between the two engines while preserving
three load-bearing differences:

- `GoFish::Game#next_player_turn` must keep its explicit `nil` return (`go_fish` returns it
  directly as `card_picked_up`); `CrazyEights::Game#next_player_turn` ignores the return value,
  so hoisting with the `nil` return preserved is safe for both.
- `number_of_cards_to_deal` must read `self.class::SMALL_GAME_MAX_SIZE`, not a lexically-bound
  constant, so each subclass's own game-size threshold is respected.
- `Card.from_json` must keep returning `[]` on blank input for `GoFish::Card` (this is load-bearing:
  `GoFish::TurnResult#go_fish_current`/`#go_fish_all`, `app/models/go_fish/turn_result.rb:92,98`,
  explicitly check `card_picked_up.is_a?(Array) && card_picked_up.empty?` to detect "no card was
  drawn" after a round-trip) and `nil` for `CrazyEights::Card`.

Also hoists `start!` (identical in both `*_game.rb` STI subclasses) to the `Game` base with an
`engine_class` hook, and hoists the `load`/`dump` serialization plumbing.

Since this is behavior-preserving, the primary regression net is the **existing** spec suite —
the work below adds only (a) one missing regression spec that pins the nil-return contract before
touching it, and (b) shared examples so the now-inherited behavior isn't asserted twice per engine.
No new user-visible behavior means no new system specs.

## Test coverage

### `spec/models/go_fish/game_spec.rb` (modify existing — add missing case)

#### `#next_player_turn`
- [ ] returns `nil` (baseline regression spec, written and passing *before* any extraction —
      pins the contract `go_fish` relies on for `card_picked_up`) — **Part 2, not started**

### `spec/support/shared_examples/card_game_card_examples.rb` (new shared examples file) — DONE

#### `it_behaves_like "a CardGame::Card"`
- [x] has a rank, suit, and value
- [x] cards of the same rank and suit are equal
- [x] raises `InvalidRank` for an invalid rank
- [x] raises `InvalidSuit` for an invalid suit
- [x] `.valid_rank?` returns false for an invalid rank / true for a valid rank / false for nil
- [x] `.value` returns the index of the rank
- [x] `#as_json` returns the expected hash
- [x] `.from_json` restores rank and suit from a round-trip

`spec/models/go_fish/card_spec.rb` and `spec/models/crazy_eights/card_spec.rb` include this
shared example instead of re-asserting the identical cases, keeping only what's genuinely
subclass-specific (`to_s`, `SPELLED_RANKS` content, `to_file_name`, `valid_suit?`,
`update_wild_suit`, and each subclass's own blank-`from_json` return value).

### `app/models/card_game/card.rb` (new) — DONE

- [x] `CardGame::Card.from_json` dispatches via `self.new` so subclasses round-trip to their own
      type (covered by the shared example's round-trip case run against both subclasses)
- [x] blank-input reconciliation: `GoFish::Card.from_json(nil)` still returns `[]`;
      `CrazyEights::Card.from_json(nil)` still returns `nil` — both asserted directly in each
      card's own spec file (not the shared example, since this is the one deliberately
      divergent case)

**Also done as part of Part 1 (not originally scoped in this doc):** `CardGame::Pile` +
`CardGame::Deck` extraction, with `spec/support/shared_examples/card_game_pile_examples.rb` and
`card_game_deck_examples.rb`, including a `card_class` type-check (`be_an_instance_of(card_class)`)
added to guard against the `card_class` hook silently building the wrong Card subclass — `Card#==`
only compares rank/suit, not class, so a plain equality check wouldn't have caught that.
`CrazyEights::Pile` deleted; `spec/models/crazy_eights/pile_spec.rb` deleted (coverage absorbed).

### `spec/models/support/shared_examples/card_game_engine_examples.rb` (new shared examples file) — Part 2, not started

#### `it_behaves_like "a CardGame::Engine"`
- [ ] `#number_of_cards_to_deal` deals `LARGE_HAND` when player count is at/under the subclass's
      own `SMALL_GAME_MAX_SIZE`, and `SMALL_HAND` above it (run once per engine with that
      engine's own constant value, proving `self.class::` resolution — not the other subclass's)
- [ ] `#start` shuffles the deck and deals
- [ ] `#next_player_turn` advances to the next player, loops back to the first player, and
      **returns `nil`** (the shared case that protects both engines going forward)
- [ ] `.load`/`.dump` round-trip: `Engine.load(Engine.dump(game)).as_json == game.as_json`
- [ ] `.load` returns `nil` for blank input

`spec/models/go_fish/game_spec.rb` and `spec/models/crazy_eights/game_spec.rb` include this
shared example for the hoisted methods, dropping their now-duplicate individual assertions for
`next_player_turn` and the load/dump round-trip (the existing round-trip tests at
`go_fish/game_spec.rb:22-44` and `crazy_eights/game_spec.rb:385-408` are consolidated into the
shared example, not deleted outright).

### `app/models/card_game/engine.rb` (new)

- [ ] `#deal` covered by each subclass's own spec via the `after_deal` hook — Crazy Eights keeps
      an example proving `deal_card_to_discard` still runs after dealing hands (existing
      coverage; re-run as regression, not rewritten)

### `spec/models/go_fish_game_spec.rb` / `spec/models/crazy_eights_game_spec.rb` (regression only)

- [ ] `#start!` existing examples (`go_fish_game_spec.rb:4-36`, and the Crazy Eights equivalent)
      re-run unchanged after hoisting `start!` to `Game` with an `engine_class` hook — no new
      cases needed since behavior is unchanged

## Related specs (regression check)

- `spec/models/go_fish/turn_result_spec.rb` — depends on `GoFish::Card.from_json`'s `[]`
  blank-return via `go_fish_current`/`go_fish_all`; run after the `CardGame::Card` extraction
- `spec/models/crazy_eights/turn_result_spec.rb` — depends on `CrazyEights::Card.from_json`'s
  `nil` blank-return; same reason
- `spec/models/go_fish/deck_spec.rb`, `spec/models/go_fish/player_spec.rb` — call
  `GoFish::Card.from_json` in `.map` during their own `from_json`; run after the `Card` extraction
- `spec/models/crazy_eights/deck_spec.rb` (if present) / `spec/models/crazy_eights/player_spec.rb`
  — same, for `CrazyEights::Card.from_json`
- `spec/models/go_fish/game_spec.rb`, `spec/models/crazy_eights/game_spec.rb` — full files, after
  the `CardGame::Engine` extraction
- `spec/models/go_fish_game_spec.rb`, `spec/models/crazy_eights_game_spec.rb` — full files, after
  the `start!` hoist
- Full suite (`bundle exec rspec`) at the end, per the source plan's "green at every step" note
