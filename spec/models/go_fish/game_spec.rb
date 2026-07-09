require 'rails_helper'

RSpec.describe GoFish::Game, type: :model do
  let(:player1) { GoFish::Player.new(name: 'player1', id: 1) }
  let(:player2) { GoFish::Player.new(name: 'player2', id: 2) }
  let(:player3) { GoFish::Player.new(name: 'player3', id: 3) }

  describe '.create' do
    context 'when a game has not already been created' do
      let!(:game) { create :started_game }
      let!(:result) { described_class.create(game.players) }
      it 'initializes a game and returns an object' do
        expected_deck_size = 38
        expect(result.players.count).to eq game.players.size
        expect(result.current_player_idx).to be_zero
        expect(result.results).to be_empty
        expect(result.deck.cards_left).to eq expected_deck_size
      end
    end
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

  describe '#run_turn' do
    let(:card1) { GoFish::Card.new('A') }
    context 'when a turn is run with 2 players' do
      context 'when players run out of cards' do
        let(:game) { described_class.new(players: [ player1, player2 ]) }
        let(:player1_data) { game.players.first }
        let(:player2_data) { game.players.last }
        context 'when player1 ends their turn with no cards' do
          before do
            player1_data.hand = [ GoFish::Card.new('J'), GoFish::Card.new('J'), GoFish::Card.new('J') ]
            player2_data.hand = [ GoFish::Card.new('J'), GoFish::Card.new('K') ]
            game.deck.cards = [ card1 ]
          end
          it 'adds card to players hand, and its still their turn' do
            game.run_turn(player2.id, 'J')
            expected_size = 1
            expect(player1_data.hand_size).to eq expected_size
            expect(game.current_player.name).to eq player1_data.name
            expect(game.latest_result.got_card.size).to eq expected_size
          end
        end

        context 'when player1 takes player2 last card and creates a book' do
          before do
            player1_data.hand = [ GoFish::Card.new('J'), GoFish::Card.new('J'), GoFish::Card.new('J') ]
            player2_data.hand = [ GoFish::Card.new('J') ]
            game.deck.cards = [ card1, card1 ]
            game.run_turn(player2.id, 'J')
          end
          it 'gives both players a new card and its still player1 turn' do
            expected_hand_size = 1
            expected_record_size = 2
            expect(player1_data.hand_size).to eq expected_hand_size
            expect(player2_data.hand_size).to eq expected_hand_size
            expect(game.current_player.name).to eq player1_data.name
            expect(game.latest_result.got_card.size).to eq expected_record_size
          end

          it 'tells turn results a book was created' do
            expect(game.latest_result.created_book).to_not be_nil
          end
        end

        context 'when player1 ends their turn with no cards and the deck is empty' do
          before do
            player1_data.hand = [ GoFish::Card.new('J'), GoFish::Card.new('J'), GoFish::Card.new('J') ]
            player2_data.hand = [ GoFish::Card.new('J'), GoFish::Card.new('K') ]
            game.deck.cards = []
          end
          it 'player1 does not get cards their turn is over' do
            game.run_turn(player2.id, 'J')
            expect(player1_data.hand_size).to be_zero
            expect(game.current_player.name).to eq player2_data.name
          end
        end
      end
      context 'when player1 is asking player2 for a card they have' do
        let(:game) { described_class.new(players: [ player1, player2 ]) }
        let!(:player1_data) { game.players.first }
        let!(:player2_data) { game.players.last }
        let(:card2) { GoFish::Card.new('2') }
        before do
          player2_data.hand << card1
          player1_data.hand << card1
          game.run_turn(player2.id, 'A')
        end
        it 'player 1 gets the cards added to their hand' do
          expected_hand_size = 2
          expect(player1_data.hand_size).to eq expected_hand_size
        end
        it 'player2 gets the cards removed from their hand and a new card added' do
          game.deck = [ card2 ]
          expected_hand_size = 1
          expect(player2_data.hand_size).to eq expected_hand_size
          expect(player2_data.hand.first).to eq card2
        end
        context 'when player1 asks player2 for a card player2 does not have' do
          before do
            game.run_turn(player2.id, 'J')
            game.deck.cards.unshift GoFish::Card.new('10')
          end
          context 'player1 does not take a card from player2' do
            it 'card is added to player1 hand from deck' do
              expected_hand_size = 3
              expect(player1_data.hand_size).to eq expected_hand_size
            end
            it 'current player is set to player2' do
              expect(game.current_player.name).to be player2_data.name
            end
          end
        end
        it 'returns a valid round result' do
          expect(game.results.last).to be_a GoFish::TurnResult
        end
      end
      context 'when player1 asks for a card player2 does have and go fishing' do
        let(:game) { described_class.new(players: [ player1, player2 ]) }
        let!(:player1_data) { game.players.first }

        context 'when they pick up that card' do
          before do
            game.deck.cards.unshift(GoFish::Card.new('A'))
            game.run_turn(player2.id, 'A')
          end

          it 'adds card to their hand' do
            expected_hand_size = 1
            expect(player1_data.hand_size).to eq expected_hand_size
          end

          it 'they are still current player' do
            expect(game.current_player.name).to eq player1_data.name
          end

          context 'when the card they picked up creates a book' do
            before do
              game.deck.cards.unshift(GoFish::Card.new('A'))
              game.players.first.hand = [ GoFish::Card.new('A'), GoFish::Card.new('A'), GoFish::Card.new('A') ]
              game.run_turn(player2.id, 'A')
            end
            it 'tells turn results a book was created' do
              expect(game.latest_result.created_book).to_not be_nil
            end
          end
        end
      end
      context 'when player1 asks a player that does not exist' do
        let(:game) { described_class.new(players: [ player1, player2 ]) }
        it 'returns nil' do
          expect(game.run_turn(3, 'J')).to be nil
        end
      end
      context 'when player1 is asking player2 for a card they do not have' do
        let(:game) { described_class.new(players: [ player1, player2 ]) }
        let!(:player1_data) { game.players.first }
        let!(:player2_data) { game.players.last }
        context 'when player1 does not pick up that card' do
          before do
            game.current_player_idx = 1
            player2_data.hand << GoFish::Card.new('J')
            game.run_turn(player1.id, 'A')
          end
          it 'card is added to player1 hand' do
            expected_hand_size = 2
            expect(player2_data.hand_size).to eq expected_hand_size
          end
          it 'current player is set to next player in queue' do
            expect(game.current_player.name).to eq player1_data.name
          end
        end
      end
      context 'when there deck is empty and a player goes fishing' do
        let(:game) { described_class.new(players: [ player1, player2 ]) }
        let!(:player1_data) { game.players.first }
        let!(:player2_data) { game.players.last }
        before do
          game.deck.cards = []
          player1_data.hand << GoFish::Card.new('J')
          player2_data.hand << GoFish::Card.new('K')
          game.run_turn(player1.id, 'A')
        end
        it 'does not give the player a card' do
          expected_hand_size = 1
          expect(player1_data.hand_size).to eq expected_hand_size
        end
        it 'sets the current player to next player in the queue' do
          expect(game.current_player.name).to eq player2_data.name
        end
      end
    end
    context 'when the next player cannot play' do
      let(:game) { described_class.new(players: [ player1, player2, player3 ]) }
      let!(:player1_data) { game.players.first }
      let!(:player2_data) { game.players[1] }
      let!(:player3_data) { game.players.last }
      before do
        game.deck.cards = []
        player1_data.hand = [ GoFish::Card.new('J') ]
        game.run_turn(player2.id, 'J')
      end
      it 'skipped them' do
        expect(game.current_player.name).to eq player1_data.name
      end
    end
  end

  describe '#winner' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    context 'when there is no winner' do
      it 'returns' do
        expect(game.winner).to be_nil
      end
      context 'when the deck is empty and all player hands are empty' do
        let!(:game_player1) { game.players.first }
        let!(:game_player2) { game.players.last }
        before do
          game.deck = []
          game_player1.hand = []
          game_player1.books = [ GoFish::Book.new('K'), GoFish::Book.new('2') ]
          game_player2.hand = []
          game_player2.books = [ GoFish::Book.new('J') ]
        end
        it 'returns the player with the most books' do
          expect(game.winner.name).to be game_player1.name
        end
        context 'when there is a tie for most books' do
          it 'returns the player with the highest book' do
            game_player1.books.pop
            expect(game.winner).to be game_player1
          end
        end
      end
    end
  end

  describe '#latest_result' do
    let(:game) { described_class.new(players: [ player1 ]) }
    let(:result) do
      GoFish::TurnResult.new(
        current_player: nil, opponent: nil,
        card_asked_for: 'K', cards_taken: nil,
        card_picked_up: nil, goes_again: nil, created_book: nil
      )
    end
    before do
      game.results << result
    end
    it 'returns last result' do
      expect(game.latest_result).to eq result
    end
  end

  describe '#next_player_turn' do
    let(:game) { described_class.new(players: [ player1, player2 ]) }
    it 'sets current player turn to player2' do
      game.next_player_turn
      expect(game.current_player).to eq player2
    end
    it 'can loop back around to player1' do
      game.next_player_turn
      game.next_player_turn
      expect(game.current_player).to eq player1
    end
  end

  describe '#turn_skipped?' do
    let(:game) { described_class.new(players: [ player1, player2 ]) }
    let(:player) { game.current_player }
    context 'when the players hand and/or the deck is not empty' do
      it 'returns false' do
        game.start
        expect(game.turn_skipped?).to be false
      end
    end
    context 'when the players hand and deck is empty' do
      it 'returns true' do
        game.deck = []
        player.hand = []
        expect(game.turn_skipped?).to be true
      end
    end
  end

   describe '#current_player' do
    let(:game) { described_class.new(players: [ player1, player2 ]) }
    it 'returns the current player' do
      expect(game.current_player).to eq player1
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

  describe '#list_of_ranks' do
    context 'when a player has 3 cards' do
      let(:game) { described_class.new(players: [ player1 ]) }
      before do
        game.players.first.hand = [ GoFish::Card.new('J'), GoFish::Card.new('J'), GoFish::Card.new('10') ]
      end

      it 'returns all of players ranks' do
        expected_size = 2
        expect(game.list_of_ranks(player1.id).size).to eq expected_size
      end
    end
  end

  describe '#list_of_players' do
    context 'when there are two players' do
      let(:player_name) { 'Player2' }
      let(:game) { described_class.new(players: [ player1, player2 ]) }
      it 'returns a list of players that is not the current player' do
        result = game.list_of_players(player1.id)
        expected_size = 1
        expect(result.size).to eq expected_size
        expect(result.first.name).to eq game.players.last.name
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

  describe '#valid_player?' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    it 'returns true if player is valid' do
      expect(game.valid_player?(player2.id)).to be true
    end

    it 'returns false if player does not exist in game' do
      expect(game.valid_player?(player1.id)).to be false
    end

    it 'returns false if player is self' do
      expect(game.valid_player?(1)).to be false
    end
  end

  describe '#valid_rank?' do
    let!(:game) { described_class.new(players: [ player1, player2 ]) }
    before do
      game.players.first.hand = [ GoFish::Card.new('J') ]
    end
    it 'returns true if rank is valid' do
      expect(game.valid_rank?('J')).to be true
    end
    it 'returns false if rank is not a valid rank' do
      expect(game.valid_rank?('H')).to be false
    end
    it 'returns false if rank is not in current players hand' do
      expect(game.valid_rank?('K')).to be false
    end
  end
end
