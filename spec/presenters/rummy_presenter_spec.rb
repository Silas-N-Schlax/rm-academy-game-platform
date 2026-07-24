require 'rails_helper'

RSpec.describe RummyPresenter do
  let!(:game) { create :game, type: 'RummyGame' }
  let(:implementation) { game.game_state }
  let(:your_user) { game.users.first }
  let(:other_user) { game.users.last }

  before do
    game.start!
    implementation.players.first.hand = [
      Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts')
    ]
    implementation.discard.cards = [ Rummy::Card.new('K', 'Diamonds') ]
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
      expect(presenter.game_type).to eq 'Rummy'
      expect(presenter.stock_count).to eq implementation.deck.cards_left
    end
  end

  describe '#discard_top' do
    it 'returns the file name of the top discard card' do
      expect(presenter_for(your_user).discard_top).to eq 'king_of_diamonds'
    end
  end

  describe '#your_name and #hand' do
    it 'returns the viewing player name and their hand as file/rank/suit hashes' do
      presenter = presenter_for(your_user)
      expect(presenter.your_name).to eq game.reload.game_state.find_player(your_user.id).name
      expect(presenter.hand).to eq [
        { card: '7_of_spades', rank: '7', suit: 'Spades', active: false },
        { card: '7_of_hearts', rank: '7', suit: 'Hearts', active: false }
      ]
    end
  end

  describe '#opponents' do
    it 'maps every other player to display attributes, never including the viewer' do
      opponents = presenter_for(your_user).opponents
      expect(opponents.map { |opponent| opponent[:name] }).to_not include(
        game.reload.game_state.find_player(your_user.id).name
      )
      expect(opponents.first).to include(hand_size: a_kind_of(Integer), melded: false, flag: '')
    end
  end

  describe '#melds' do
    it 'maps each meld to its card file names and whether it is full' do
      implementation.melds = [ Rummy::Meld.new(cards: [ Rummy::Card.new('7', 'Diamonds') ]) ]
      game.game_state = implementation
      game.save!

      expect(presenter_for(your_user).melds).to eq [ { cards: [ '7_of_diamonds' ], full: false } ]
    end
  end

  describe '#winner_name and #ranking' do
    it 'is blank and empty before the game has a winner' do
      presenter = presenter_for(your_user)
      expect(presenter.winner_name).to eq ''
      expect(presenter.ranking).to eq []
    end

    it 'names the winner and ranks the remaining players by pip total once someone goes out' do
      implementation.players.first.hand = []
      game.game_state = implementation
      game.save!

      presenter = presenter_for(your_user)
      expect(presenter.winner_name).to eq implementation.players.first.name
      expect(presenter.ranking).to eq [
        { place: 2, name: implementation.players.last.name, flag: '', pips: implementation.players.last.hand_pip_total }
      ]
    end
  end

  describe '#awaiting_draw' do
    it 'is true when it is your turn and you still need to draw' do
      expect(presenter_for(your_user).awaiting_draw).to be true
    end

    it 'is false once the current result already has a draw source' do
      implementation.current_result.draw_source = 'stock'
      game.game_state = implementation
      game.save!

      expect(presenter_for(your_user).awaiting_draw).to be false
    end
  end

  describe '#turn_timer_seconds' do
    it 'returns whatever was passed in at construction, for the view to read without a parallel local' do
      expect(presenter_for(your_user, turn_timer_seconds: 30).turn_timer_seconds).to eq 30
    end
  end

  describe '#your_flag and #feed' do
    it 'are blank placeholders, unchanged from the inline board hash' do
      presenter = presenter_for(your_user)
      expect(presenter.your_flag).to eq ''
      expect(presenter.feed).to eq []
    end
  end

  describe '#error' do
    it 'is blank when no turn is given' do
      expect(presenter_for(your_user).error).to be_nil
    end

    it 'surfaces the base error from an invalid turn' do
      turn = RummyTurn.new(game: game, user: other_user)
      turn.valid?

      expect(presenter_for(your_user, turn: turn).error).to eq 'Its not your turn!'
    end
  end
end
