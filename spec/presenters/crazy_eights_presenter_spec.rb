require 'rails_helper'

RSpec.describe CrazyEightsPresenter do
  let!(:game) { create :game, type: 'CrazyEightsGame' }
  let(:implementation) { game.game_state }
  let(:your_user) { game.users.first }
  let(:other_user) { game.users.last }

  before do
    game.start!
    implementation.players.first.hand = [ CrazyEights::Card.new('7', 'Spades'), CrazyEights::Card.new('7', 'Hearts') ]
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
      expect(presenter.game_type).to eq 'Crazy Eights'
      expect(presenter.stock_count).to eq implementation.deck.cards_left
    end
  end

  describe '#discard_top and #wild_suit' do
    it 'exposes the file name of the top discard card' do
      expect(presenter_for(your_user).discard_top).to eq implementation.discard.top_card.to_file_name
    end

    it 'is blank when no wild suit is in effect' do
      expect(presenter_for(your_user).wild_suit).to be_nil
    end

    it 'exposes the currently chosen wild suit' do
      implementation.wild_suit = 'Hearts'
      game.game_state = implementation
      game.save!

      expect(presenter_for(your_user).wild_suit).to eq 'Hearts'
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
      expect(opponents.first).to include(id: game.reload.game_state.players.last.id, hand_size: a_kind_of(Integer))
    end

    it 'defaults every opponent to the placeholder avatar' do
      expect(presenter_for(your_user).opponents.first[:avatar_url]).to eq '/default_avatar.png'
    end

    it 'flags the opponent whose turn it currently is' do
      expect(presenter_for(other_user).opponents.first[:current_turn]).to be true
    end

    it 'is blank for an opponent with no recorded turns yet' do
      expect(presenter_for(your_user).opponents.first[:last_action]).to eq ''
    end

    it "summarizes an opponent's most recent turn" do
      opponent_player = implementation.players.last
      implementation.results = [
        CrazyEights::TurnResult.new(current_player: opponent_player, card_played: CrazyEights::Card.new('9'),
                                     cards_drawn: [], occurred_at: Time.current)
      ]
      game.game_state = implementation
      game.save!

      expected_text = "#{opponent_player.name} played a 9 of Spades"
      expect(presenter_for(your_user).opponents.first[:last_action]).to eq expected_text
    end
  end

  describe '#winner_name and #ranking' do
    it 'is blank and empty before the game has a winner' do
      presenter = presenter_for(your_user)
      expect(presenter.winner_name).to eq ''
      expect(presenter.ranking).to eq []
    end

    it 'names the winner and ranks the remaining players by fewest cards once the game ends' do
      implementation.players.first.hand = []
      implementation.players.last.hand = [ CrazyEights::Card.new('2') ]
      game.game_state = implementation
      game.save!

      presenter = presenter_for(your_user)
      expect(presenter.winner_name).to eq implementation.players.first.name
      expect(presenter.ranking).to eq [
        { place: 2, name: implementation.players.last.name, flag: '', cards_left: 1, score: '1 card left' }
      ]
    end

    it 'describes what the ranking is ordered by' do
      expect(presenter_for(your_user).ranking_subtitle).to eq 'Ranked by fewest cards left'
    end
  end

  describe '#error' do
    it 'is blank when no turn is given' do
      expect(presenter_for(your_user).error).to be_nil
    end

    it 'surfaces the base error from an invalid turn' do
      turn = CrazyEightsTurn.new(game: game, user: your_user, rank: 'K', suit: 'Obi')
      turn.valid?

      expect(presenter_for(your_user, turn: turn).error).to eq 'Invalid player or rank!'
    end
  end

  describe '#feed' do
    it 'is empty before any turn has finished' do
      expect(presenter_for(your_user).feed).to eq []
    end

    context 'once turns have been recorded' do
      let(:older) do
        CrazyEights::TurnResult.new(current_player: implementation.players.first, card_played: CrazyEights::Card.new('2'),
                                     cards_drawn: [], occurred_at: Time.zone.parse('2024-01-01 11:00:00'))
      end
      let(:newer) do
        CrazyEights::TurnResult.new(current_player: implementation.players.last, card_played: CrazyEights::Card.new('7'),
                                     cards_drawn: [], occurred_at: Time.zone.parse('2024-01-01 11:58:00'))
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

  describe '#action_notice' do
    it 'is blank before any turn has finished' do
      expect(presenter_for(your_user).action_notice).to eq ''
    end

    context 'once a turn has been recorded' do
      let(:result) do
        CrazyEights::TurnResult.new(current_player: implementation.players.first, card_played: CrazyEights::Card.new('9'),
                                     cards_drawn: [])
      end

      before do
        implementation.results = [ result ]
        game.game_state = implementation
        game.save!
      end

      it "is the latest turn's last feed line, from the viewer's point of view" do
        expect(presenter_for(your_user).action_notice).to eq result.feed_lines(your_user.id).last[:text]
      end
    end
  end
end
