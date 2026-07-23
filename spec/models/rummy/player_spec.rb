require 'rails_helper'

RSpec.describe Rummy::Player, type: :model do
  describe '#add_cards' do
    let(:player) { described_class.new(name: 'player1', id: 1) }
    let(:card1) { Rummy::Card.new('A', 'Spades') }
    let(:card2) { Rummy::Card.new('K', 'Spades') }

    context 'when player has no cards' do
      it 'adds cards in order' do
        player.add_cards([ card1, card2 ])
        expect(player.hand).to eq [ card1, card2 ]
      end
    end

    context 'when player already has cards' do
      let(:card3) { Rummy::Card.new('2', 'Spades') }
      before { player.hand = [ card3 ] }

      it 'appends the new cards' do
        player.add_cards([ card1, card2 ])
        expect(player.hand).to eq [ card3, card1, card2 ]
      end
    end
  end

  describe '#as_json' do
    let!(:player) { described_class.new(name: 'player1', id: 1) }
    let(:expected_hash) do
      {
        "name" => 'player1',
        "id" => 1,
        "hand" => [ { "rank" => 'J', "suit" => 'Spades' } ]
      }
    end

    it 'returns expected hash' do
      player.hand = [ Rummy::Card.new('J') ]
      expect(player.as_json).to eq expected_hash
    end
  end

  describe '.from_json' do
    let!(:player) { described_class.new(name: 'player1', id: 1) }
    before { player.hand = [ Rummy::Card.new('J') ] }

    it 'restores the state of the player' do
      json = player.as_json
      expect(described_class.from_json(json)).to have_attributes(
        name: player.name,
        id: player.id,
        hand: player.hand
      )
    end
  end
end
