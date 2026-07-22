# Rummy Rules (as implemented)

This mirrors the in-app rules page (planned: `/rules`, content-driven from `config/games.yml` via
the `GameCatalog` model) and the planned `Rummy::Game` engine. Rules are deliberately adapted from
the traditional in-person game to work online — when the engine is built, keep this doc, the rules
page, and the engine in sync.

- **Players:** 2–6.
- **Pack:** a standard 52-card deck. No jokers, no wild cards.
- **Object:** be the first to "go out" — get rid of every card in your hand by forming it into
  matched sets (melds).
- **Rank order (for runs):** A (low) 2 3 4 5 6 7 8 9 10 J Q K. **Rule change:** the Ace is **low
  only** — `A-2-3` (same suit) is a valid run, `Q-K-A` is **not**, and runs never wrap around
  (`K-A-2` is invalid). This keeps run logic simple and matches the Ace = 1 pip value.
- **Matched sets (melds):**
  - **Set (group):** 3 or 4 cards of the same rank, each a different suit (only one of each card
    exists in a single deck, so a set is at most four cards).
  - **Run (sequence):** 3 or more consecutive cards of the **same suit** (e.g. 4♥ 5♥ 6♥).
- **The deal:** dealer deals one card at a time face down, starting with the player to the left.
  2 players → 10 cards each; 3–4 players → 7 each; 5–6 players → 6 each. The rest form the
  face-down **stock**. The top stock card is turned face up beside it to start the **discard
  pile** (the first upcard).
- **A turn (in order):**
  - **Draw one card** — either the top of the stock **or** the top of the discard pile (only the
    top discard card is visible/available). You may always take the top discard card, including
    when it's the last one (leaving the discard pile empty). **Rule:** if you took the top discard
    card, you may not discard that same card on this turn. **Rule:** if both the stock and the
    discard pile are empty when it's your turn to draw, you cannot draw — skip the draw and play
    your turn as normal (optionally meld/lay off), then discard as usual.
  - **Lay down melds (optional):** put down any number of new melds from your hand.
  - **Lay off (optional):** add cards from your hand onto melds already on the table — onto a set,
    the missing same-rank card (up to four total); onto a run, a same-suit card that extends either
    end in sequence. **Rule change:** you may only lay off after you have laid down at least one
    meld of your own at some point this game.
  - **Discard one card** face up onto the discard pile — unless you are going out (below).
- **Melds are fixed:** once laid on the table, melds cannot be rearranged, split, or taken back.
- **Going out / winning:** you go out when your hand is empty. On your final turn you may either
  (a) meld/lay off down to one card and discard it, or (b) meld/lay off your entire remaining hand
  with no final discard. Either ends the game immediately. The player who goes out **wins**.
- **Ranking everyone else:** there is no running score across hands and no doubling "rummy" bonus.
  When the game ends, the remaining players are ranked by the **total pip value left in their
  hands, lowest first**. Pip values: face cards (K, Q, J) = 10 each, Ace = 1, every other card its
  face value.
- **Stock exhaustion:** if the stock runs out and no one has gone out, the discard pile — minus its
  current top card — is turned over **without shuffling** to form a new stock, and play continues.
  This recycling is **unlimited**.

## Edge cases and how they resolve

| Scenario | Behavior |
|---|---|
| First player's very first turn | Normal turn rules apply — they may take the starting upcard or draw from stock. |
| Player took the top discard card, tries to re-discard it same turn | Not allowed — rejected before the move is applied. |
| Player tries to lay off before laying down any meld of their own | Not allowed — the must-meld-first gate rejects it. |
| Invalid meld (fewer than 3 cards, mixed suits in a run, non-consecutive run, wrong-rank set) | Rejected by `RummyTurn` validations before it reaches the engine. |
| Lay-off doesn't fit the target meld (wrong rank for a set, doesn't extend a run in-suit/in-sequence) | Rejected by validation. |
| Card not in the player's hand, or not the player's turn | Rejected by `Turn` / `RummyTurn` validations. |
| Stock empty when a player must draw, discard has ≥2 cards | Recycle discard (minus top) into a new stock, no shuffle; unlimited recycles. |
| Stock empty, discard has 1 card | Player may take that last discard card as their draw (emptying the discard pile). |
| Stock empty **and** discard empty at draw time | Player cannot draw — the draw step is skipped. They still play as normal (optionally meld/lay off) and discard one card (unless going out), which returns a card to the discard pile for the next player. No hard deadlock, no special end condition. |
| Two passive players never meld and keep recycling | **Known risk with unlimited recycling** — the hand can loop indefinitely. A turn timer (deferred) is the intended mitigation. |

## Deferred features (revisit after the base game works)

- **Turn timer** — reuse the server-authoritative pattern already built for Go Fish
  (`GoFishGame#remaining_turn_seconds`, `app/javascript/controllers/timer_controller.js`). On
  timeout, auto-draw + auto-discard to keep the game moving and mitigate the recycling loop.
- **Player disconnect / reconnect handling** — none exists platform-wide today.
- **Cumulative multi-hand scoring** and the **"rummy" doubling bonus** — if we later want
  traditional match play to a target score.
- **Full discard-pile visibility** and other quality-of-life UI, if desired.
- **Auto-suggest button** that cycles through possible melds / playable cards and pre-selects them
  in-hand — a hint/assist cycler for players who are stuck.
- **Swap players-column side** — a toggle to move the opponents panel to the other side of the
  board.
