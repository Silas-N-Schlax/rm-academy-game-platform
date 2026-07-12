require 'rails_helper'

RSpec.describe CrazyEights::Game, type: :model do
  let(:player1) { CrazyEights::Player.new(name: 'player1', id: 1) }
  let(:player2) { CrazyEights::Player.new(name: 'player2', id: 2) }
  let(:player3) { CrazyEights::Player.new(name: 'player3', id: 3) }
  let(:player4) { CrazyEights::Player.new(name: 'player3', id: 4) }

  describe '#start' do
    context 'when a game is started with 2 players' do
      let!(:game) { described_class.new(players: [ player1, player2 ]) }
      let(:game_player1) { game.players.first }
      let(:game_player2) { game.players.last }
      before { game.start }
      it 'deals 7 cards to each player' do
        game.players.each do |player|
          expect(player.hand_size).to eq CrazyEights::Game::LARGE_HAND
        end
      end

      it 'cards are not in order' do
        default_hand1 = [ CrazyEights::Card.new('2'), CrazyEights::Card.new('4'), CrazyEights::Card.new('6'), CrazyEights::Card.new('8'), CrazyEights::Card.new('10') ]
        default_hand2 = [ CrazyEights::Card.new('3'), CrazyEights::Card.new('5'), CrazyEights::Card.new('7'), CrazyEights::Card.new('9'), CrazyEights::Card.new('J') ]
        expect(game_player1.hand).to_not eq default_hand1
        expect(game_player2.hand).to_not eq default_hand2
        expect(game_player1.hand).to_not be_empty
        expect(game_player2.hand).to_not be_empty
      end

      it 'deals one card to the discard pile' do
        expect(game.discard.top_card).to_not be_nil
      end
    end

    context 'when a game is started with 4 players' do
      let!(:game) { described_class.new(players: [ player1, player2, player3, player4 ]) }
      before { game.start }
      it 'deals 5 cards to each player' do
        game.players.each do |player|
          expect(player.hand_size).to eq CrazyEights::Game::SMALL_HAND
        end
      end
    end
  end


  describe '#play_card' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    before { game.start }
    let(:player) { game.players.first }
    before do
      game.discard.cards = [ CrazyEights::Card.new('J') ]
      game.players.first.hand = [ CrazyEights::Card.new('J', 'Hearts'), CrazyEights::Card.new('2', 'Hearts') ]
    end
    context 'when the the card is valid' do
      let!(:expected_hand_size) { player.hand_size - 1 }
      let!(:expected_discard_pile_size) { game.discard.cards_left + 1 }
      before do
        game
        game.play_card(rank: 'J', suit: 'Hearts')
      end
      it 'plays card and finished turn' do
        expect(player.hand_size).to eq expected_hand_size
        expect(game.discard.cards_left).to eq expected_discard_pile_size
        expect(game.current_player).to_not eq player
        expect(game.results.size).to_not be_zero
        expect(game.current_result.current_player.id).to_not eq game.latest_result.current_player.id
      end
    end

    context 'when the card is valid and its a wild' do
      let(:wild_suit) { 'Diamonds' }
       before do
         player.hand.unshift CrazyEights::Card.new('8')
        game
        game.play_card(rank: '8', suit: 'Spades', wild_suit:)
      end
      it 'adds the correct wild suit to that card' do
        top_discarded_card = game.discard.top_card
        expect(top_discarded_card.wild_suit).to eq wild_suit
      end
    end

    context 'when the card is valid and its the last players turn' do
      before do
        game.current_player_idx = game.players.size - 1
        game.current_player.hand = [ CrazyEights::Card.new('2') ]
      end
      it 'wraps player index back to the first player' do
        game.play_card(rank: '2', suit: 'Spades')
        expect(game.current_player.id).to eq player.id
      end
    end

    context 'when there is a winner' do
      it 'returns winner' do
        player.hand = []
        expect(game.play_card(rank: nil, suit: nil)).to eq player
      end
    end

    context 'when the user does not have the card they want to play' do
      it 'returns false' do
        expect(game.play_card(rank: '10', suit: 'Spades')).to be false
      end
    end

    context 'when the card is invalid' do
      it 'returns false' do
        expect(game.play_card(rank: 'K', suit: 'L')).to be false
      end
    end
  end

  describe '#request_cards' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    before { game.start }
    let(:player) { game.players.first }
    before do
      game.discard.cards = [ CrazyEights::Card.new('J') ]
      game.deck.cards = [ CrazyEights::Card.new('2') ]
      player.hand = [ CrazyEights::Card.new('10', 'Hearts'), CrazyEights::Card.new('2', 'Hearts') ]
    end
    context 'when player does not have any cards to play' do
      context 'when they have to pick up one card' do
        before { game.request_cards }
        it 'adds top card from deck to player hand' do
          expected_hand_size = 3
          expected_discard_pile_size = 1
          expected_drawn_cards = 1
          expect(game.players.first.hand_size).to eq expected_hand_size
          expect(game.deck.empty?).to be true
          expect(game.discard.cards_left).to eq expected_discard_pile_size
          expect(game.current_result.cards_drawn.size).to eq expected_drawn_cards
        end
      end

      context 'when they have to pick up numerous cards' do
        before { game.deck.cards = [ CrazyEights::Card.new('2', 'Hearts'), CrazyEights::Card.new('3', 'Hearts'), CrazyEights::Card.new('2'), CrazyEights::Card.new('4') ] }
        it 'adds cards until they get a card they can play' do
          game.request_cards
          expected_hand_size = 5
          expected_deck_size = 1
          expected_discard_pile_size = 1
          expect(game.players.first.hand_size).to eq expected_hand_size
          expect(game.deck.cards_left).to eq expected_deck_size
          expect(game.discard.cards_left).to eq expected_discard_pile_size
        end
      end

      context 'when the deck is empty' do
        let(:original_discard_array) { [ CrazyEights::Card.new('9'), CrazyEights::Card.new('3'), CrazyEights::Card.new('5'), CrazyEights::Card.new('4') ] }
        before do
          game.deck.cards = [ CrazyEights::Card.new('10', 'Hearts') ]
          game.discard.cards = original_discard_array
        end
        it 'takes all but 1 card form discard, adds to deck and shuffles then gives 1 card to player' do
          game.request_cards
          expected_hand_size = 4
          expected_deck_size = 2
          expected_discard_pile_size = 1
          expect(game.players.first.hand_size).to eq expected_hand_size
          expect(game.deck.cards_left).to eq expected_deck_size
          expect(game.discard.cards_left).to eq expected_discard_pile_size
        end
      end

      context 'when the deck and discard run out' do
        before do
          game.deck.cards = [ CrazyEights::Card.new('10') ]
          player.hand = [ CrazyEights::Card.new('7', 'Diamonds') ]
          game.discard.cards = [ CrazyEights::Card.new('9', 'Hearts') ]
        end
        it 'skip players turn' do
          game.request_cards
          expected_hand_size = 2
          expect(game.current_player.id).to_not eq player.id
          expect(game.current_player).to be_a CrazyEights::Player
          expect(game.players.first.hand_size).to eq expected_hand_size
        end
      end
    end

    context 'when player has a card to player' do
      before { player.hand = [ CrazyEights::Card.new('3') ] }
      it 'returns false' do
        expect(game.request_cards).to be false
      end
    end

    context 'when there is a winner' do
       it 'returns winner' do
        player.hand = []
        expect(game.request_cards).to eq player
      end
    end
  end

  describe '#winner?' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    before { game.start }
    it 'returns true when there is a winner' do
      game.players.first.hand = []
      expect(game.winner?).to be true
    end

    it 'returns false when there is not a winner' do
      expect(game.winner?).to be false
    end
  end

  describe '#winning_player' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    before { game.start }
    it 'returns true when there is a winner' do
      player1 = game.players.first
      player1.hand = []
      expect(game.winning_player).to be player1
    end

    it 'returns nil when there is not a winner' do
      expect(game.winning_player).to be nil
    end
  end

  describe 'current_player' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    it 'returns the current player' do
      expect(game.current_player).to eq player1
    end
  end

  describe '#latest_result' do
    let(:game) { described_class.new(players: [ player1 ]) }
    let(:result) do
      CrazyEights::TurnResult.new(
        current_player: game.current_player,
        card_played: CrazyEights::Card.new('J'),
        cards_drawn: [ CrazyEights::Card.new('J') ]
      )
    end
    before do
      game.results << result
    end
    it 'returns last result' do
      expect(game.latest_result).to eq result
    end
  end

  describe '#valid_card?' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    it 'returns true if valid' do
      expect(game.valid_card?('J', 'Spades')).to be false
    end

    it 'returns false in invalid rank' do
      expect(game.valid_card?('0', 'Spades')).to be false
    end

    it 'returns false if invalid suit' do
      expect(game.valid_card?('J', 'Obi')).to be false
    end

    it 'returns false if player does not have rank or suit' do
      expect(game.valid_card?('K', 'Hearts')).to be false
    end
  end

  describe '#find_player' do
    let(:game) { described_class.new(players: [ player1, player2 ]) }
    context 'when provided with id for player1' do
      it 'returns player1' do
        result = game.find_player(player1.id)
        expect(result.name).to eq player1.name
      end
    end

    context 'when provided with an id for a non-existent player' do
      it 'returns nil' do
        player3_id = 3
        result = game.find_player(player3_id)
        expect(result).to be_nil
      end
    end
  end

  describe '#as_json' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    let(:card) { CrazyEights::Card.new('J') }
    before do
      game.deck.cards = [ card ]
      game.discard.cards = [ card ]
      game.results = [ CrazyEights::TurnResult.new(card_played: card, cards_drawn: [], current_player: nil) ]
    end
    it 'returns expected hash' do
      expect(game.as_json).to eq expected_game_hash
    end
  end

  describe '.create' do
    context 'when a game has not already been created' do
      let!(:game) { create :started_game }
      let!(:result) { described_class.create(game.players) }
      it 'initializes a game and returns an object' do
        expected_deck_size = 37
        expected_discard_pile_size = 1
        expect(result.players.size).to eq game.players.size
        expect(result.current_player_idx).to be_zero
        expect(result.results).to be_empty
        expect(result.deck.cards_left).to eq expected_deck_size
        expect(result.discard.cards_left).to eq expected_discard_pile_size
      end
    end
  end

  describe '.dump' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    let(:card) { CrazyEights::Card.new('J') }
    before do
      game.deck.cards = [ card ]
      game.discard.cards = [ card ]
      game.results = [ CrazyEights::TurnResult.new(card_played: card, cards_drawn: [], current_player: nil) ]
    end
    it 'returns expected hash' do
      expect(CrazyEights::Game.dump(game)).to eq expected_game_hash
    end
  end

  describe '.load' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    let(:card) { CrazyEights::Card.new('J') }
    before do
      game.deck.cards = [ card ]
      game.discard.cards = [ card ]
      game.results = [ CrazyEights::TurnResult.new(card_played: card, cards_drawn: [], current_player: nil) ]
    end
    it 'restores current state of the card' do
      json = game.as_json
      expect(CrazyEights::Game.load(json).as_json).to eq json
    end
  end

  def expected_game_hash
    {
        "players" => [
          {
            "name" => 'player1',
            "id" => 1,
            "hand" => []
          },
          {
            "name" => 'player2',
            "id" => 2,
            "hand" => []
          }
        ],
        "deck" => [
          {
            "rank" => 'J',
            "suit" => 'Spades',
            "wild_suit" => nil
          }
        ],
        "discard" => [
          {
            "rank" => 'J',
            "suit" => 'Spades',
            "wild_suit" => nil
          }
        ],
        "results" => [
          {
            "card_played" => {
               "rank" => 'J',
              "suit" => 'Spades',
              "wild_suit" => nil
            },
            "cards_drawn" => [],
            "current_player" => nil
          }
        ],
        "current_player_idx" => 0
      }
  end
end
