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

    it 'defaults every opponent to the placeholder avatar' do
      expect(presenter_for(your_user).opponents.first[:avatar_url]).to eq '/default_avatar.png'
    end

    it "flags the opponent whose turn it currently is" do
      expect(presenter_for(other_user).opponents.first[:current_turn]).to be true
    end

    it 'is blank for an opponent with no recorded turns yet' do
      expect(presenter_for(your_user).opponents.first[:last_action]).to eq ''
    end

    it "summarizes an opponent's most recent turn" do
      implementation.results = [
        Rummy::TurnResult.new(current_player: implementation.players.last, card_discarded: Rummy::Card.new('3', 'Diamonds'),
                               occurred_at: Time.current)
      ]
      game.game_state = implementation
      game.save!

      expect(presenter_for(your_user).opponents.first[:last_action]).to eq 'Discarded the 3 of Diamonds'
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

  describe '#your_flag' do
    it 'is a blank placeholder, unchanged from the inline board hash' do
      expect(presenter_for(your_user).your_flag).to eq ''
    end
  end

  describe '#feed' do
    it 'is empty before any turn has finished' do
      expect(presenter_for(your_user).feed).to eq []
    end

    context 'once turns have been recorded' do
      let(:older) do
        Rummy::TurnResult.new(current_player: implementation.players.first, card_discarded: Rummy::Card.new('2', 'Clubs'),
                               occurred_at: Time.zone.parse('2024-01-01 11:00:00'))
      end
      let(:newer) do
        Rummy::TurnResult.new(current_player: implementation.players.last, card_discarded: Rummy::Card.new('3', 'Diamonds'),
                               occurred_at: Time.zone.parse('2024-01-01 11:58:00'))
      end

      before do
        implementation.results = [ older, newer ]
        game.game_state = implementation
        game.save!
      end

      it 'orders turns newest first, with actor, relative time, and feed lines' do
        travel_to Time.zone.parse('2024-01-01 12:00:00') do
          expect(presenter_for(your_user).feed).to eq [
            { actor: implementation.players.last.name, time: '2 mins ago',
              lines: [ { text: 'Discarded the 3 of Diamonds', kind: :discard } ] },
            { actor: 'You', time: '1 hour ago',
              lines: [ { text: 'Discarded the 2 of Clubs', kind: :discard } ] }
          ]
        end
      end
    end

    context 'relative time formatting' do
      def feed_time_for(occurred_at, now:)
        implementation.results = [ Rummy::TurnResult.new(current_player: implementation.players.first, occurred_at: occurred_at) ]
        game.game_state = implementation
        game.save!
        travel_to(now) { presenter_for(your_user).feed.first[:time] }
      end

      it 'says "Just now" for anything under a minute old' do
        now = Time.zone.parse('2024-01-01 12:00:00')
        expect(feed_time_for(now - 30.seconds, now: now)).to eq 'Just now'
      end

      it 'shows whole days once past the hour mark' do
        now = Time.zone.parse('2024-01-01 12:00:00')
        expect(feed_time_for(now - 2.days, now: now)).to eq '2 days ago'
      end

      it 'falls back to "A while ago" once past 30 days' do
        now = Time.zone.parse('2024-01-01 12:00:00')
        expect(feed_time_for(now - 31.days, now: now)).to eq 'A while ago'
      end
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
