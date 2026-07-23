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
        "current_player_idx" => 0
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
end
