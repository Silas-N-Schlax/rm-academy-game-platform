# Crazy Eights Rules (as implemented)

There's no in-app rules page for Crazy Eights yet (unlike Go Fish) — this doc is the source of truth until one exists. Rules are deliberately adapted from the traditional in-person game to work online; see `app/models/crazy_eights/game.rb` for the engine.

- **Players:** 2–7. **Pack:** standard 52-card deck. **8s are wild** (`CrazyEights::Card::WILD_RANK`).
- **The deal:** 2–3 players → 7 cards each; 4–7 players → 5 cards each, dealt starting with the first player. The next card becomes the starting discard-pile card.
  - If that starting card would be an 8, it's shuffled back into the deck and a new starting card is drawn — repeated as many times as needed until the drawn card isn't an 8. An 8 can never be the opening discard.
- **A turn:** the current player must play a card matching the top discard's **rank or suit**, or play an 8 (wild) on anything.
  - Playing an 8 requires choosing a new suit for play to continue on (prompted separately in the UI) — the engine tracks this as `wild_suit`, which overrides the discard's actual suit for matching purposes until the next non-wild card is played.
  - **Rule change from the standard game:** if a player has no legal card to play, they must draw from the stock pile **repeatedly until they draw a playable card** (not just one card as in traditional rules).
  - **Rule change:** a player who currently has a legal card **cannot** choose to draw instead — drawing/"requesting" only does anything if you have no playable card. (The traditional optional "draw even if you can play" rule is intentionally disabled here.)
- **Stock pile empty:** when the draw pile runs out, the discard pile (all cards except the current top card) is shuffled and becomes the new stock pile, and drawing continues from there.
- **Edge case — only 1 discard + 0 stock:** if the discard pile has just one card (the top card, nothing to reshuffle) and the stock pile is also empty, there's nothing to draw — the player's turn is skipped instead of looping forever.
- **End of game:** the moment a player's hand is empty, the game ends immediately — no going out "on" a played card in any special sense, just an empty hand.
- **No ties** — there is always exactly one winner (first player to empty their hand).

## Edge cases and how they resolve

| Scenario | Behavior |
|---|---|
| Draw pile empty during a required draw | Reshuffle discard (minus top card) into a new draw pile, keep drawing |
| Player has no playable card | Must draw until a playable card is drawn (see above) |
| Player tries to draw but has a playable card | Not allowed — request is a no-op (`request_cards` returns `false`) |
| Player attempts an invalid play (wrong rank/suit, card not in hand, doesn't match top discard) | Move rejected by `CrazyEightsGame#valid_move?` / `CrazyEightsTurn` validations before it reaches the engine |
| Player plays an 8 | Must submit a `wild_suit` in the same move; that suit governs legal follow-up plays until overridden by the next wild |
| Discard has 1 card and draw pile is empty | Turn is skipped (no infinite draw loop) |
| First card drawn to start the discard pile is an 8 | Shuffled back into the deck, a new card is drawn, repeated until it's not an 8 |
