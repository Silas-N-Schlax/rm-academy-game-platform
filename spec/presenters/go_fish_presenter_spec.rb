require 'rails_helper'

RSpec.describe GoFishPresenter do
  let!(:game) { create :game, type: 'GoFishGame' }
  let(:implementation) { game.game_state }
  let(:your_user) { game.users.first }
  let(:other_user) { game.users.last }

  before do
    game.start!
    implementation.players.first.hand = [ GoFish::Card.new('7', 'Spades'), GoFish::Card.new('7', 'Hearts') ]
    game.game_state = implementation
    game.save!
  end

  def presenter_for(user, turn: nil, turn_timer_seconds: nil)
    described_class.new(game.reload, user, turn: turn, turn_timer_seconds: turn_timer_seconds)
  end

  describe '#your_turn and #turn_label' do
    it 'is true and says "Your Turn" for the current player' do
      presenter = presenter_for(your_user)
      expect(presenter.your_turn).to be true
      expect(presenter.turn_label).to eq 'Your Turn'
    end

    it 'is false and names the current player for anyone else' do
      presenter = presenter_for(other_user)
      expect(presenter.your_turn).to be false
      expect(presenter.turn_label).to eq "#{game.reload.game_state.current_player.name}'s Turn"
    end
  end

  describe '#name, #game_type, #stock_count' do
    it 'exposes the game name, type, and remaining stock size' do
      presenter = presenter_for(your_user)
      expect(presenter.name).to eq game.name
      expect(presenter.game_type).to eq 'Go Fish'
      expect(presenter.stock_count).to eq implementation.deck.cards_left
    end
  end

  describe '#your_name and #hand' do
    it 'returns the viewing player name and their hand as file/rank/suit hashes' do
      presenter = presenter_for(your_user)
      expect(presenter.your_name).to eq game.reload.game_state.find_player(your_user.id).name
      expect(presenter.hand).to eq [
        { card: '7_of_spades', rank: '7', suit: 'Spades' },
        { card: '7_of_hearts', rank: '7', suit: 'Hearts' }
      ]
    end
  end

  describe '#your_books' do
    it 'is empty before the viewer has completed any book' do
      expect(presenter_for(your_user).your_books).to eq []
    end

    it 'returns the file name of each completed book once the viewer has one' do
      implementation.players.first.books = [ GoFish::Book.new('K') ]
      game.game_state = implementation
      game.save!

      expect(presenter_for(your_user).your_books).to eq [ 'king_of_hearts' ]
    end
  end

  describe '#hand_disabled' do
    it 'is false when it is your turn' do
      expect(presenter_for(your_user).hand_disabled).to be false
    end

    it 'is true when it is not your turn' do
      expect(presenter_for(other_user).hand_disabled).to be true
    end
  end

  describe '#opponents' do
    it 'maps every other player to display attributes, never including the viewer' do
      opponents = presenter_for(your_user).opponents
      expect(opponents.map { |opponent| opponent[:name] }).to_not include(
        game.reload.game_state.find_player(your_user.id).name
      )
      expect(opponents.first).to include(id: game.reload.game_state.players.last.id, hand_size: a_kind_of(Integer), book_count: 0)
    end

    it 'defaults every opponent to the placeholder avatar' do
      expect(presenter_for(your_user).opponents.first[:avatar_url]).to eq '/default_avatar.png'
    end

    it 'flags the opponent whose turn it currently is' do
      expect(presenter_for(other_user).opponents.first[:current_turn]).to be true
    end

    it "exposes a hand-back placeholder per card and each book's file name" do
      implementation.players.last.hand = [ GoFish::Card.new('2', 'Clubs'), GoFish::Card.new('3', 'Clubs') ]
      implementation.players.last.books = [ GoFish::Book.new('K') ]
      game.game_state = implementation
      game.save!

      opponent = presenter_for(your_user).opponents.first
      expect(opponent[:hand_backs].size).to eq 2
      expect(opponent[:books]).to eq [ 'king_of_hearts' ]
    end
  end

  describe '#winner_name and #ranking' do
    it 'is blank and empty before the game has a winner' do
      presenter = presenter_for(your_user)
      expect(presenter.winner_name).to eq ''
      expect(presenter.ranking).to eq []
    end

    it 'names the winner and ranks the remaining players by books once the game ends' do
      implementation.players.each { |player| player.hand = [] }
      implementation.deck.cards = []
      implementation.players.first.books = [ GoFish::Book.new('K') ]
      game.game_state = implementation
      game.save!

      presenter = presenter_for(your_user)
      expect(presenter.winner_name).to eq implementation.players.first.name
      expect(presenter.ranking).to eq [
        { place: 2, name: implementation.players.last.name, flag: '', books: 0, score: '0 books' }
      ]
    end

    it 'describes what the ranking is ordered by' do
      expect(presenter_for(your_user).ranking_subtitle).to eq 'Ranked by books, most first'
    end
  end

  describe '#error' do
    it 'is blank when no turn is given' do
      expect(presenter_for(your_user).error).to be_nil
    end

    it 'surfaces the base error from an invalid turn' do
      turn = GoFishTurn.new(game: game, user: other_user)
      turn.valid?

      expect(presenter_for(your_user, turn: turn).error).to eq 'Its not your turn!'
    end
  end

  describe '#feed' do
    it 'is empty before any turn has finished' do
      expect(presenter_for(your_user).feed).to eq []
    end

    context 'once turns have been recorded' do
      let(:older) do
        GoFish::TurnResult.new(current_player: implementation.players.first, opponent: implementation.players.last,
                                cards_taken: [], rank_asked_for: '2', card_picked_up: nil, goes_again: false,
                                occurred_at: Time.zone.parse('2024-01-01 11:00:00'))
      end
      let(:newer) do
        GoFish::TurnResult.new(current_player: implementation.players.last, opponent: implementation.players.first,
                                cards_taken: [ GoFish::Card.new('7') ], rank_asked_for: '7', card_picked_up: nil,
                                goes_again: true, occurred_at: Time.zone.parse('2024-01-01 11:58:00'))
      end

      before do
        implementation.results = [ older, newer ]
        game.game_state = implementation
        game.save!
      end

      it 'orders turns newest first, with actor, relative time, and feed lines' do
        travel_to Time.zone.parse('2024-01-01 12:00:00') do
          expect(presenter_for(your_user).feed).to eq [
            { actor: implementation.players.last.name, time: '2 mins ago', lines: newer.feed_lines(your_user.id) },
            { actor: 'You', time: '1 hour ago', lines: older.feed_lines(your_user.id) }
          ]
        end
      end
    end
  end
end
