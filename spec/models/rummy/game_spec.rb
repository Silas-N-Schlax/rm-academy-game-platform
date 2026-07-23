require 'rails_helper'

RSpec.describe Rummy::Game, type: :model do
  let(:player1) { Rummy::Player.new(name: 'player1', id: 1) }
  let(:player2) { Rummy::Player.new(name: 'player2', id: 2) }
  let(:player3) { Rummy::Player.new(name: 'player3', id: 3) }
  let(:player4) { Rummy::Player.new(name: 'player4', id: 4) }
  let(:player5) { Rummy::Player.new(name: 'player5', id: 5) }
  let(:player6) { Rummy::Player.new(name: 'player6', id: 6) }

  it_behaves_like "a CardGame::Engine"

  describe '#start' do
    context 'with 2 players' do
      let!(:game) { described_class.new(players: [ player1, player2 ]) }
      before { game.start }
      it 'deals 10 cards to each player' do
        game.players.each { |player| expect(player.hand.size).to eq 10 }
      end
    end

    context 'with 3-4 players' do
      let!(:game) { described_class.new(players: [ player1, player2, player3, player4 ]) }
      before { game.start }
      it 'deals 7 cards to each player' do
        game.players.each { |player| expect(player.hand.size).to eq 7 }
      end
    end

    context 'with 5-6 players' do
      let!(:game) { described_class.new(players: [ player1, player2, player3, player4, player5, player6 ]) }
      before { game.start }
      it 'deals 6 cards to each player' do
        game.players.each { |player| expect(player.hand.size).to eq 6 }
      end
    end

    context 'stock and discard setup' do
      let!(:game) { described_class.new(players: [ player1, player2 ]) }
      before { game.start }
      it 'flips exactly one card to the discard pile' do
        expect(game.discard.cards_left).to eq 1
      end

      it 'puts the remaining cards in the stock' do
        expected_stock_size = 52 - (2 * 10) - 1
        expect(game.deck.cards_left).to eq expected_stock_size
      end
    end
  end

  describe '#as_json' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    let(:card) { Rummy::Card.new('J') }
    before do
      game.deck.cards = [ card ]
      game.discard.cards = [ card ]
    end
    let(:expected_hash) do
      {
        "players" => [ player1.as_json, player2.as_json ],
        "deck" => [ card.as_json ],
        "discard" => [ card.as_json ],
        "current_player_idx" => 0,
        "results" => [],
        "melds" => [],
        "current_result" => Rummy::TurnResult.new(current_player: player1).as_json
      }
    end

    it 'returns expected hash' do
      expect(game.as_json).to eq expected_hash
    end
  end

  describe '.load' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    before { game.start }
    it 'restores the exact same state' do
      json = game.as_json
      expect(described_class.load(json).as_json).to eq json
    end
  end

  describe '#must_draw?' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }

    it 'returns true when the stock has cards' do
      game.deck.cards = [ Rummy::Card.new('2') ]
      game.discard.cards = []
      expect(game.must_draw?).to be true
    end

    it 'returns true when only the discard has cards' do
      game.deck.cards = []
      game.discard.cards = [ Rummy::Card.new('2') ]
      expect(game.must_draw?).to be true
    end

    it 'returns false when both the stock and discard are empty' do
      game.deck.cards = []
      game.discard.cards = []
      expect(game.must_draw?).to be false
    end
  end

  describe '#draw' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    let(:top_stock_card) { Rummy::Card.new('9', 'Diamonds') }
    let(:top_discard_card) { Rummy::Card.new('K', 'Spades') }

    before do
      game.deck.cards = [ top_stock_card ]
      game.discard.cards = [ top_discard_card ]
    end

    context 'from the stock' do
      it 'moves the top stock card into the current player hand' do
        game.draw(source: 'stock')
        expect(player1.hand).to include top_stock_card
        expect(game.deck.empty?).to be true
      end

      it 'records the draw on the current turn result' do
        game.draw(source: 'stock')
        expect(game.current_result.draw_source).to eq 'stock'
        expect(game.current_result.card_drawn).to eq top_stock_card
      end
    end

    context 'from the discard pile' do
      it 'moves the top discard card into the current player hand' do
        game.draw(source: 'discard')
        expect(player1.hand).to include top_discard_card
        expect(game.discard.empty?).to be true
      end

      it 'records the draw on the current turn result' do
        game.draw(source: 'discard')
        expect(game.current_result.draw_source).to eq 'discard'
        expect(game.current_result.card_drawn).to eq top_discard_card
      end
    end
  end

  describe '#recycle_stock!' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    let(:top_discard_card) { Rummy::Card.new('Q', 'Hearts') }

    before do
      game.deck.cards = []
      game.discard.cards = [ top_discard_card, Rummy::Card.new('J', 'Clubs'), Rummy::Card.new('10', 'Diamonds') ]
    end

    it 'moves every discard card but the top one into the stock' do
      game.recycle_stock!
      expect(game.deck.cards_left).to eq 2
      expect(game.discard.cards_left).to eq 1
      expect(game.discard.top_card).to eq top_discard_card
    end

    context 'when a stock draw needs to recycle first' do
      it 'recycles, then draws a card, leaving 1 card behind in the stock' do
        game.draw(source: 'stock')
        expect(game.deck.cards_left).to eq 1
        expect(game.discard.cards_left).to eq 1
        expect(game.current_result.recycled_stock).to be true
      end
    end
  end

  describe '#lay_down_meld' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    let(:seven_spades) { Rummy::Card.new('7', 'Spades') }
    let(:seven_hearts) { Rummy::Card.new('7', 'Hearts') }
    let(:seven_diamonds) { Rummy::Card.new('7', 'Diamonds') }
    let(:extra_card) { Rummy::Card.new('9', 'Clubs') }

    before { player2.hand = [ Rummy::Card.new('2') ] }

    context 'with a valid set of cards' do
      before { player1.hand = [ seven_spades, seven_hearts, seven_diamonds, extra_card ] }

      it 'moves the cards from the hand onto a new meld' do
        game.lay_down_meld([ seven_spades, seven_hearts, seven_diamonds ])
        expect(game.melds.size).to eq 1
        expect(player1.hand).to eq [ extra_card ]
      end

      it 'marks the player as having melded' do
        game.lay_down_meld([ seven_spades, seven_hearts, seven_diamonds ])
        expect(player1.has_melded).to be true
      end

      it 'records the meld on the current turn result' do
        game.lay_down_meld([ seven_spades, seven_hearts, seven_diamonds ])
        expect(game.current_result.melds_laid_down.size).to eq 1
      end

      it 'does not end the turn when the hand is not empty' do
        game.lay_down_meld([ seven_spades, seven_hearts, seven_diamonds ])
        expect(game.current_player).to eq player1
      end
    end

    context 'with an invalid set of cards' do
      before { player1.hand = [ Rummy::Card.new('2', 'Clubs'), Rummy::Card.new('5', 'Diamonds'), Rummy::Card.new('9', 'Hearts') ] }

      it 'returns false and does not change the hand' do
        cards = player1.hand.dup
        expect(game.lay_down_meld(cards)).to be false
        expect(player1.hand).to eq cards
        expect(game.melds).to be_empty
      end
    end

    context 'when melding empties the hand' do
      before { player1.hand = [ seven_spades, seven_hearts, seven_diamonds ] }

      it 'ends the game immediately, with no discard required' do
        game.lay_down_meld([ seven_spades, seven_hearts, seven_diamonds ])
        expect(game.winner?).to be true
        expect(game.winning_player).to eq player1
      end

      it 'does not advance to the next player' do
        game.lay_down_meld([ seven_spades, seven_hearts, seven_diamonds ])
        expect(game.current_player).to eq player1
      end
    end
  end

  describe '#winner?' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }

    it 'returns false when no player has an empty hand' do
      player1.hand = [ Rummy::Card.new('2') ]
      player2.hand = [ Rummy::Card.new('3') ]
      expect(game.winner?).to be false
    end

    it 'returns true when a player has an empty hand' do
      player1.hand = []
      player2.hand = [ Rummy::Card.new('3') ]
      expect(game.winner?).to be true
    end
  end

  describe '#winning_player' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }

    it 'returns the player with the empty hand' do
      player1.hand = [ Rummy::Card.new('2') ]
      player2.hand = []
      expect(game.winning_player).to eq player2
    end

    it 'returns nil when no one has won' do
      player1.hand = [ Rummy::Card.new('2') ]
      player2.hand = [ Rummy::Card.new('3') ]
      expect(game.winning_player).to be_nil
    end
  end

  describe '#lay_off' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    let(:existing_meld) do
      Rummy::Meld.new(cards: [ Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts'), Rummy::Card.new('7', 'Hearts') ])
    end
    let(:eight_hearts) { Rummy::Card.new('8', 'Hearts') }
    let(:extra_card) { Rummy::Card.new('9', 'Clubs') }

    before do
      game.melds = [ existing_meld ]
      player2.hand = [ Rummy::Card.new('2') ]
    end

    context 'when the player has already melded and the cards fit' do
      before do
        player1.has_melded = true
        player1.hand = [ eight_hearts, extra_card ]
      end

      it 'moves the cards from the hand into the target meld' do
        game.lay_off(0, [ eight_hearts ])
        expect(existing_meld.cards).to include eight_hearts
        expect(player1.hand).to eq [ extra_card ]
      end

      it 'records the lay-off on the current turn result' do
        game.lay_off(0, [ eight_hearts ])
        expect(game.current_result.lay_offs).to eq [ { meld: existing_meld, cards: [ eight_hearts ] } ]
      end

      it 'does not end the turn when the hand is not empty' do
        game.lay_off(0, [ eight_hearts ])
        expect(game.current_player).to eq player1
      end
    end

    context 'when the player has not melded yet' do
      before { player1.hand = [ eight_hearts ] }

      it 'returns false and leaves the hand untouched' do
        expect(game.lay_off(0, [ eight_hearts ])).to be false
        expect(player1.hand).to eq [ eight_hearts ]
        expect(existing_meld.cards.size).to eq 3
      end
    end

    context 'when the cards do not fit the target meld' do
      before do
        player1.has_melded = true
        player1.hand = [ Rummy::Card.new('2', 'Clubs') ]
      end

      it 'returns false and leaves the hand untouched' do
        expect(game.lay_off(0, [ Rummy::Card.new('2', 'Clubs') ])).to be false
        expect(existing_meld.cards.size).to eq 3
      end
    end

    context 'when the meld index does not exist' do
      before do
        player1.has_melded = true
        player1.hand = [ eight_hearts ]
      end

      it 'returns false without raising' do
        expect(game.lay_off(5, [ eight_hearts ])).to be false
      end
    end

    context 'when laying off empties the hand' do
      before do
        player1.has_melded = true
        player1.hand = [ eight_hearts ]
      end

      it 'ends the game immediately' do
        game.lay_off(0, [ eight_hearts ])
        expect(game.winner?).to be true
        expect(game.winning_player).to eq player1
      end
    end
  end

  describe '#discard_card' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    let(:two_clubs) { Rummy::Card.new('2', 'Clubs') }
    let(:extra_card) { Rummy::Card.new('9', 'Diamonds') }

    before { player2.hand = [ Rummy::Card.new('3') ] }

    context 'when the hand still has cards left' do
      before { player1.hand = [ two_clubs, extra_card ] }

      it 'moves the card from the hand onto the discard pile' do
        game.discard_card(two_clubs)
        expect(player1.hand).to eq [ extra_card ]
        expect(game.discard.top_card).to eq two_clubs
      end

      it 'records the discard on the turn result before flushing it to results' do
        game.discard_card(two_clubs)
        expect(game.results.last.card_discarded).to eq two_clubs
      end

      it 'advances the turn to the next player' do
        game.discard_card(two_clubs)
        expect(game.current_player).to eq player2
      end
    end

    context 'when discarding empties the hand' do
      before { player1.hand = [ two_clubs ] }

      it 'ends the game immediately, without advancing the turn' do
        game.discard_card(two_clubs)
        expect(game.winner?).to be true
        expect(game.winning_player).to eq player1
        expect(game.current_player).to eq player1
      end
    end
  end

  describe '#ranking' do
    let!(:game) { described_class.new(players: [ player1, player2, player3 ]) }

    it 'ranks the non-winning players ascending by pip total, excluding the winner' do
      player1.hand = []
      player2.hand = [ Rummy::Card.new('K'), Rummy::Card.new('A') ]
      player3.hand = [ Rummy::Card.new('2') ]

      expect(game.ranking).to eq [ player3, player2 ]
    end
  end

  describe '#cards_from_ids' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    let(:seven_hearts) { Rummy::Card.new('7', 'Hearts') }

    before { player1.hand = [ seven_hearts ] }

    it 'resolves matching ids to the actual hand cards' do
      expect(game.cards_from_ids([ '7:Hearts' ])).to eq [ seven_hearts ]
    end

    it 'resolves to nil for an id not in the hand' do
      expect(game.cards_from_ids([ '8:Spades' ])).to eq [ nil ]
    end
  end

  describe '#valid_move?' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }

    context 'action: draw' do
      before { player1.hand = [ Rummy::Card.new('2') ] }

      it 'is valid to draw from the stock when the stock has cards' do
        game.deck.cards = [ Rummy::Card.new('9') ]
        expect(game.valid_move?(action: 'draw', source: 'stock')).to be true
      end

      it 'is invalid to draw from the stock when empty with only 1 discard card' do
        game.deck.cards = []
        game.discard.cards = [ Rummy::Card.new('K') ]
        expect(game.valid_move?(action: 'draw', source: 'stock')).to be false
      end

      it 'is valid to draw from the stock when empty but the discard has 2+ (recycle)' do
        game.deck.cards = []
        game.discard.cards = [ Rummy::Card.new('K'), Rummy::Card.new('Q') ]
        expect(game.valid_move?(action: 'draw', source: 'stock')).to be true
      end

      it 'is invalid once a draw has already happened this turn' do
        game.deck.cards = [ Rummy::Card.new('9'), Rummy::Card.new('8') ]
        game.draw(source: 'stock')
        expect(game.valid_move?(action: 'draw', source: 'stock')).to be false
      end
    end

    context 'action: meld' do
      let(:cards) { [ Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'), Rummy::Card.new('7', 'Diamonds') ] }

      before { player1.hand = cards }

      it 'is invalid before drawing, when a draw was possible' do
        game.deck.cards = [ Rummy::Card.new('9') ]
        expect(game.valid_move?(action: 'meld', card_ids: [ '7:Spades', '7:Hearts', '7:Diamonds' ])).to be false
      end

      it 'is valid after drawing, for a valid meld' do
        game.deck.cards = [ Rummy::Card.new('9') ]
        game.draw(source: 'stock')
        expect(game.valid_move?(action: 'meld', card_ids: [ '7:Spades', '7:Hearts', '7:Diamonds' ])).to be true
      end

      it 'is invalid for an invalid meld' do
        game.deck.cards = [ Rummy::Card.new('9') ]
        game.draw(source: 'stock')
        expect(game.valid_move?(action: 'meld', card_ids: [ '7:Spades', '7:Hearts' ])).to be false
      end

      it 'is valid without drawing first when no draw was possible' do
        game.deck.cards = []
        game.discard.cards = []
        expect(game.valid_move?(action: 'meld', card_ids: [ '7:Spades', '7:Hearts', '7:Diamonds' ])).to be true
      end
    end

    context 'action: layoff' do
      let(:eight_hearts) { Rummy::Card.new('8', 'Hearts') }
      let(:existing_meld) do
        Rummy::Meld.new(cards: [ Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts'), Rummy::Card.new('7', 'Hearts') ])
      end

      before do
        game.melds = [ existing_meld ]
        player1.hand = [ eight_hearts ]
        game.deck.cards = []
        game.discard.cards = []
      end

      it 'is invalid before the player has melded' do
        expect(game.valid_move?(action: 'layoff', card_ids: [ '8:Hearts' ], meld_index: 0)).to be false
      end

      it 'is valid once melded and the cards fit the target meld' do
        player1.has_melded = true
        expect(game.valid_move?(action: 'layoff', card_ids: [ '8:Hearts' ], meld_index: 0)).to be true
      end

      it 'is invalid for a stale meld index' do
        player1.has_melded = true
        expect(game.valid_move?(action: 'layoff', card_ids: [ '8:Hearts' ], meld_index: 5)).to be false
      end

      it 'is invalid when the cards do not fit the meld' do
        player1.has_melded = true
        player1.hand = [ Rummy::Card.new('2', 'Clubs') ]
        expect(game.valid_move?(action: 'layoff', card_ids: [ '2:Clubs' ], meld_index: 0)).to be false
      end
    end

    context 'action: discard' do
      let(:two_clubs) { Rummy::Card.new('2', 'Clubs') }

      before do
        game.deck.cards = []
        game.discard.cards = [ two_clubs ]
      end

      it 'is invalid to discard the exact card just drawn from the discard pile' do
        player1.hand = [ Rummy::Card.new('9') ]
        game.draw(source: 'discard')
        expect(game.valid_move?(action: 'discard', card_ids: [ '2:Clubs' ])).to be false
      end

      it 'is valid to discard any other card' do
        player1.hand = [ Rummy::Card.new('9') ]
        game.draw(source: 'discard')
        expect(game.valid_move?(action: 'discard', card_ids: [ '9:Spades' ])).to be true
      end

      it 'is valid to discard the just-drawn discard card when it is the only card left (going out)' do
        player1.hand = []
        game.draw(source: 'discard')
        expect(game.valid_move?(action: 'discard', card_ids: [ '2:Clubs' ])).to be true
      end
    end

    it 'is invalid when a card id does not resolve to a card in hand' do
      player1.hand = []
      expect(game.valid_move?(action: 'discard', card_ids: [ '9:Spades' ])).to be false
    end
  end
end
