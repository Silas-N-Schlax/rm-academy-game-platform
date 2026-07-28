# Feature: Leaderboard page

## Feature summary

A new `/leaderboard` page lists every user ranked by total wins, then total games, then win/loss
ratio, then total time played, then account age (older wins) as a deterministic tiebreak. Every
user appears, including users with zero finished games (shown with `—` for ratio and time). The
signed-in user's own row is highlighted, and the page states "You're #N of X players". All four
stats (games, wins, ratio, time) come from a single grouped SQL query added to the existing `Stat`
model, scoped to **finished games only** — which also surfaces a pre-existing data bug:
`Game#end_game` only ever sets `winner: true` on the winning `Player`, leaving every other player's
`winner` at `nil` — indistinguishable from a player in a game that hasn't finished yet. This card
fixes that at the source (`end_game` now writes `winner: false` for every non-winning player when a
game ends) and additionally scopes `Stat`'s aggregate columns to finished games, since `total_games`
still needs to exclude in-progress/waiting games regardless of the `winner` fix.

Desktop shows a table with word-label column headers. Below 768px, the labels are replaced by icon
triggers that reveal an Optics tooltip on tap (`:focus-visible`) as well as hover, since Optics only
ships `:hover` today.

## Test coverage

### `spec/models/go_fish_game_spec.rb` (modify existing) — root-cause fix, written first

Per the Prove-It pattern: this is a bug fix, so the reproduction test comes before any change to
`Game#end_game`. `end_game` is private, reached only through a concrete game type's `#play`; GoFish
is used because `spec/models/go_fish_game_spec.rb:61-77` ("when the game is over") already builds a
finished 2-player game and is the natural place to extend, per the existing `describe '#play'` block.

#### `#play` — "when the game is over" (extend existing example)

- [ ] the non-winning player's `winner` is `false`, not `nil`, once the game ends (currently fails —
      `end_game` never touches any player but the winner)

#### `#play` — new example, 3-player game

- [ ] every non-winning player's `winner` is `false` when a 3+ player game ends (guards against a
      fix that only special-cases the two-player case — `end_game` must update **all** other
      players in the game, not just "the other one")

> Not duplicating this same assertion into `crazy_eights_game_spec.rb` / `rummy_game_spec.rb`: the
> fix lives in the shared, private `Game#end_game`, so one game type proves the shared code path.
> The full suite run at the end still exercises all three and would catch a regression.

### `spec/models/stat_spec.rb` (modify existing)

#### bug fix — finished-games scoping (Prove-It, written first)

- [ ] `#total_games` does not count a game with no `finished_at` (currently over-counts)
- [ ] `#total_losses` does not count a game with no `finished_at` — this is now largely a
      consequence of the `end_game` fix above (a non-finished game's players stay `nil`, and
      `total_losses` only ever matched `winner: nil`), but is worth its own example since `Stat`
      is a separate seam from `Game`
- [ ] existing `#total_games`/`#total_wins`/`#total_losses`/`#total_average` expectations updated to
      reflect the new finished-only denominator (numbers re-derived by hand, not copied forward)
- [ ] existing `_by_game` variant expectations updated the same way

#### `#leaderboard`

- [ ] orders by total wins descending when wins differ
- [ ] breaks a wins tie by total games descending
- [ ] breaks a wins-and-games tie by win/loss ratio descending
- [ ] breaks a wins-and-games-and-ratio tie by total time played descending
- [ ] breaks a tie on every other column by account age, older first (`created_at` ascending)
- [ ] excludes an in-progress game (`started_at` present, `finished_at` nil) from every column
- [ ] excludes an archived-but-never-finished game from every column
- [ ] a user with zero finished games appears in the results with `nil` win percentage and zero
      seconds played
- [ ] returns one row per user, not one row per game (grouping sanity check)
- [ ] issues exactly one SQL query (`ActiveRecord::QueryRecorder`-style count, or asserting on
      `.to_sql` shape if a query counter isn't already in use in this codebase — check
      `spec/support/` first)

### `spec/helpers/application_helper_spec.rb` (new file)

#### `#formatted_duration`

- [ ] formats a whole number of seconds as `HH:MM:SS`, zero-padded
- [ ] formats a duration over 24 hours (three-digit or more hour count, no wraparound)
- [ ] returns `—` for `nil`
- [ ] returns `—` for `0` (a user with zero finished games, not "00:00:00")

#### `#formatted_percentage`

- [ ] formats a float as `N.N%`
- [ ] returns `—` for `nil`

### `spec/system/leaderboard_spec.rb` (new file)

#### visiting the leaderboard

- [ ] shows every user's name, in rank order (wins desc, matching the model spec's ordering rules —
      not re-deriving the tiebreak logic here, just confirming the page reflects it)
- [ ] shows total games, total wins, W/L ratio and time played for each user
- [ ] highlights the signed-in user's own row (asserts the `leaderboard__row--you` class, per the
      house style of pinning expected selectors into a local before asserting)
- [ ] shows "You're #N of X players" with the correct numbers
- [ ] shows the top three rows with their podium classes (`leaderboard__row--first` /
      `--second` / `--third`)
- [ ] shows `—` instead of `0.0%` / `00:00:00` for a user with no finished games
- [ ] redirects a signed-out visitor (existing `Authentication` concern — confirms no new gap, not
      testing the concern itself)

#### mobile viewport (`:js`, resized to a phone width)

- [ ] shows an icon trigger for each stat column instead of the word label
- [ ] each icon trigger has `data-tooltip-position="bottom"` (regression guard — `.table`'s
      `contain: paint` silently clips a `top`-positioned tooltip)
- [ ] tapping/focusing a stat icon reveals its tooltip text (`:js`, since `:focus-visible` needs a
      real browser)

## Related specs (regression check)

- `spec/system/stats_spec.rb` — the existing `/stats` page's numbers change once `Stat`'s
  finished-games scoping lands
- `spec/models/stat_spec.rb` — covered above, but run the whole file, not just the new examples
- `spec/models/go_fish_game_spec.rb` / `crazy_eights_game_spec.rb` / `rummy_game_spec.rb` — all three
  call the shared, now-changed `Game#end_game`; only GoFish gets a new assertion, but all three must
  stay green
- `spec/system/games_spec.rb` — touches the same `Game`/`Player` factories and the sidebar nav
  partial being edited for the new leaderboard link
- Full suite before considering the card done, per AGENTS.md
