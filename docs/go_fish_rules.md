# Go Fish Rules (as implemented)

This mirrors the in-app rules page (`app/views/pages/rules.html.slim`) and the `GoFish::Game` engine (`app/models/go_fish/game.rb`). If you change the engine, update the rules page too — they're expected to stay in sync.

- **Players:** 2–6. **Pack:** standard 52-card deck.
- **Object:** win the most "books" (four of a kind, any suit). Suits don't matter for play — only rank.
- **Rank order:** Ace (high) down to 2 (low) — used only for the tie-breaker at the end.
- **The deal:** 2 players → 7 cards each; 3–6 players → 5 cards each. Remaining cards form the stock/draw pile.
- **A turn:** the current player asks one opponent for a specific rank they already hold at least one of.
  - If the opponent has any cards of that rank, the asking player takes **all** of them and goes again (ask again, same or different opponent/rank).
  - If not, the asking player draws the top card of the stock pile ("fishing"). If it's the rank they asked for, they go again; otherwise their turn ends and play passes to the next player.
  - If the stock pile is empty when a player would have to fish, their turn simply ends (no card drawn).
- **Running out of cards mid-turn:** if a player's hand becomes empty (either because all their cards of the requested rank were taken, or after fishing), they immediately draw a new card from the stock pile if any remain — this applies both to the player being asked and to the current player, independent of whose "go again" it is.
- **Skipped turns:** if the stock pile is empty **and** the current player has no cards, their turn is skipped entirely and play advances until a player with cards is found.
- **Books:** whenever a player collects all four cards of a rank, that's a book — it's set aside and those four cards leave their hand.
- **End of game:** the game ends when the stock pile is empty and every player's hand is empty.
- **Winner:** most books wins. Tie on book count → compare the **rank value of each tied player's single highest-value book** (Ace high, 2 low); higher wins. (Note: the current implementation only compares between two tied players, not an arbitrary number — see `GoFish::Game#winning_player`.)
