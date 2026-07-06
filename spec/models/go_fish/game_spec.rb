require 'rails_helper'

RSpec.describe GoFish::Game, type: :model do
  let(:player1) { GoFish::Player.new(name: 'player1', id: 1) }
  let(:player2) { GoFish::Player.new(name: 'player2', id: 2) }

  describe '.create' do
    context 'when a game has not already been created' do
      let!(:game) { create :started_game }
      let!(:player1) { create(:player, user: create(:user), game:) }
      let!(:player2) { create(:player, user: create(:user2), game:) }
      let(:players) { [ player1, player2 ] }
      let!(:result) { described_class.create(players) }
      it 'initializes a game and returns an object' do
        expected_deck_size = 38
        expect(result.players.count).to eq players.count
        expect(result.current_player_idx).to be_zero
        expect(result.results).to be_empty
        expect(result.deck.cards_left).to eq expected_deck_size
      end
    end

    context 'when a game has already been created'
  end

  describe '.load' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    let(:game_player1) { game.players.first }
    let(:game_player2) { game.players.last }
    before { game.start }
    it 'loads the current game state to an object' do
      loaded_game = GoFish::Game.load(described_class.dump(game))
      expected_deck_size = 38
      expect(loaded_game.players.count).to eq game.players.count
      expect(loaded_game.current_player_idx).to be_zero
      expect(loaded_game.results).to be_empty
      expect(loaded_game.deck.cards_left).to eq expected_deck_size
    end
    it 'returns nil if the state is empty' do
      expect(described_class.load({})).to be nil
    end
  end

  describe '.dump' do
    let!(:game) { described_class.new(players: [ player1, player2 ], deck: [ GoFish::Card.new('J') ]) }
    it 'returns as hash' do
      expect(GoFish::Game.dump(game)).to be_a Hash
    end
  end

  describe '#start' do
    context 'when a game is started with two players' do
      let(:game) { described_class.new(players: [ player1, player2 ]) }
      let(:game_player1) { game.players.first }
      let(:game_player2) { game.players.last }
      before { game.start }
      it 'deals 7 cards to each player' do
        expected_hand_size = 7
        game.players.each do |player|
          expect(player.hand_size).to eq expected_hand_size
        end
      end
      it 'cards are not in order' do
        default_hand1 = [ GoFish::Card.new('2'), GoFish::Card.new('4'), GoFish::Card.new('6'), GoFish::Card.new('8'), GoFish::Card.new('10') ]
        default_hand2 = [ GoFish::Card.new('3'), GoFish::Card.new('5'), GoFish::Card.new('7'), GoFish::Card.new('9'), GoFish::Card.new('J') ]
        expect(game_player1.hand).to_not eq default_hand1
        expect(game_player2.hand).to_not eq default_hand2
        expect(game_player1.hand).to_not be_empty
        expect(game_player2.hand).to_not be_empty
      end
    end
    context 'when a game is started with 4 players' do
      let(:player3) { GoFish::Player.new(name: 'player3', id: 3) }
      let(:player4) { GoFish::Player.new(name: 'player4', id: 4)  }
      let(:game) { described_class.new(players: [ player1, player2, player3, player4 ]) }
      before { game.start }
      it 'deals 5 cards to each player' do
        expected_hand_size = 5
        game.players.each do |player|
          expect(player.hand_size).to eq expected_hand_size
        end
      end
    end
  end

  describe '#as_json' do
    let(:card) { GoFish::Card.new('J') }
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    let(:expected_hash) do
      {
        "players" => [
          {
            "name" => player1.name,
            "id" => player1.id,
            "books" => [],
            "hand" =>  [
              "rank" => 'J',
              "suit" => 'Spades'
            ]
          },
          {
            "name" => player2.name,
            "id" => player2.id,
            "books" => [],
            "hand" =>  [
              "rank" => 'J',
              "suit" => 'Spades'
            ]
          }
        ],
        "deck" => [
          {
            "rank" => 'J',
            "suit" => 'Spades'
          }
        ],
        "current_player_idx" => 0,
        "results" => []
      }
    end
    before do
      game.deck = [ card ]
      game.players.each do |player|
        player.hand = [ card ]
      end
    end
    it 'returns expected hash' do
      expect(GoFish::Game.dump(game)).to eq expected_hash
    end
  end
end
