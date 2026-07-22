RSpec.shared_examples "a CardGame::Engine" do
  describe '#current_player' do
    let(:game) { described_class.new(players: [ player1, player2 ]) }
    it 'returns the player at current_player_idx' do
      expect(game.current_player).to eq player1
    end
  end

  describe '#find_player' do
    let(:game) { described_class.new(players: [ player1, player2 ]) }
    it 'returns the matching player' do
      expect(game.find_player(player1.id).name).to eq player1.name
    end

    it 'returns nil for an unknown id' do
      unknown_id = 999
      expect(game.find_player(unknown_id)).to be_nil
    end
  end

  describe '#latest_result' do
    let(:game) { described_class.new(players: [ player1 ]) }
    it 'returns the last result' do
      game.results << :a_result
      expect(game.latest_result).to eq :a_result
    end
  end

  describe '#next_player_turn' do
    let(:game) { described_class.new(players: [ player1, player2 ]) }
    it 'moves to the next player' do
      game.next_player_turn
      expect(game.current_player).to eq player2
    end

    it 'wraps back around to the first player' do
      game.next_player_turn
      game.next_player_turn
      expect(game.current_player).to eq player1
    end

    it 'returns nil' do
      expect(game.next_player_turn).to be_nil
    end
  end

  describe '.create' do
    let!(:game) { create(:started_game, player_count: 2) }
    it 'builds players using the engine player_class' do
      result = described_class.create(game.players)
      expect(result.players).to all(be_an_instance_of(described_class.player_class))
    end

    context 'when the players are not passed in join order' do
      it 'still seats the first-joined player as the current player' do
        first_joined_player = game.players.first
        out_of_order_players = game.players.to_a.reverse
        result = described_class.create(out_of_order_players)
        expect(result.current_player.id).to eq first_joined_player.user_id
      end
    end
  end

  describe '.load' do
    it 'returns nil if the state is empty' do
      expect(described_class.load({})).to be_nil
    end
  end

  describe '.load/.dump round trip' do
    let(:game) { described_class.new(players: [ player1, player2 ]) }
    before { game.start }
    it 'restores the exact same state' do
      restored = described_class.load(described_class.dump(game))
      expect(restored.as_json).to eq game.as_json
    end
  end
end
