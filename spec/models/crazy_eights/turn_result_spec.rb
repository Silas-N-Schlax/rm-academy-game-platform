require 'rails_helper'

RSpec.describe CrazyEights::TurnResult, type: :model do
  let(:current_player) { CrazyEights::Player.new(name: 'player') }
  let(:card_played) { CrazyEights::Card.new('J') }
  let(:cards_drawn) { [ CrazyEights::Card.new('K'), CrazyEights::Card.new('J', 'Hearts') ] }
  let(:result) do
    CrazyEights::TurnResult.new(
      card_played: card_played,
      current_player: current_player,
      cards_drawn: cards_drawn,
    )
  end

  describe '#messages_for_current' do
    it 'returns correct messages when a wild was not played' do
      messages = result.messages_for_current
      expected_drew_cards_message = 'You drew a King of Spades, and Jack of Hearts'
      expected_played_card_message = 'You played a Jack of Spades'
      expect(messages[0]).to eq expected_drew_cards_message
      expect(messages[1]).to eq expected_played_card_message
    end

    it 'returns the correct messages when a wild was played' do
      result.wild_suit = 'Hearts'
      result.card_played = CrazyEights::Card.new('8', 'Spades')
      messages = result.messages_for_current
      expected_drew_cards_message = 'You drew a King of Spades, and Jack of Hearts'
      expected_played_card_message = 'You played a wild! The suit is Hearts'
      expect(messages[0]).to eq expected_drew_cards_message
      expect(messages[1]).to eq expected_played_card_message
    end

    it 'returns the correct message when no cards were drawn' do
      result.cards_drawn = []
      messages = result.messages_for_current
      expected_played_card_message = 'You played a Jack of Spades'
      expect(messages[0]).to be_nil
      expect(messages[1]).to eq expected_played_card_message
    end

    it 'returns the correct message when no cards have been played' do
      result.card_played = nil
      messages = result.messages_for_current
      expected_played_card_message = 'You drew a King of Spades, and Jack of Hearts'
      expect(messages[0]).to eq expected_played_card_message
      expect(messages[1]).to be_nil
    end

    it 'returns all messages correct if cards have been played and drawn' do
      expected_messages_count = 2
      expect(result.messages_for_current.size).to eq expected_messages_count
    end
  end

  describe '#messages_for_all' do
     it 'returns correct messages when a wild was not played' do
      messages = result.messages_for_all
      expected_drew_cards_message = "#{result.current_player.name} drew a King of Spades, and Jack of Hearts"
      expected_played_card_message = "#{result.current_player.name} played a Jack of Spades"
      expect(messages[0]).to eq expected_drew_cards_message
      expect(messages[1]).to eq expected_played_card_message
    end

    it 'returns the correct messages when a wild was played' do
      result.wild_suit = 'Hearts'
      result.card_played = CrazyEights::Card.new('8', 'Spades')
      messages = result.messages_for_all
      expected_drew_cards_message = "#{result.current_player.name} drew a King of Spades, and Jack of Hearts"
      expected_played_card_message = "#{result.current_player.name} played a wild! The suit is Hearts"
      expect(messages[0]).to eq expected_drew_cards_message
      expect(messages[1]).to eq expected_played_card_message
    end

    it 'returns the correct message when no cards were drawn' do
      result.cards_drawn = []
      messages = result.messages_for_all
      expected_played_card_message = "#{result.current_player.name} played a Jack of Spades"
      expect(messages[0]).to be_nil
      expect(messages[1]).to eq expected_played_card_message
    end

    it 'returns the correct message when no cards have been played' do
      result.card_played = nil
      messages = result.messages_for_all
      expected_played_card_message = "#{result.current_player.name} drew a King of Spades, and Jack of Hearts"
      expect(messages[0]).to eq expected_played_card_message
      expect(messages[1]).to be_nil
    end

    it 'returns all messages correct if cards have been played and drawn' do
      expected_messages_count = 2
      expect(result.messages_for_all.size).to eq expected_messages_count
    end
  end

  describe '#add_to_drawn_card' do
    it 'adds a card to the drawn cards array' do
      result.add_to_drawn_card(CrazyEights::Card.new('J'))
      expected_drawn_cards_size = 3
      expect(result.cards_drawn.size).to eq expected_drawn_cards_size
    end
  end

  describe '#as_json' do
    it 'returns expected hash' do
      expect(result.as_json).to eq expected_hash
    end
  end

  describe '.from_json' do
    it 'restores current state of the card' do
      json = result.as_json
      expect(CrazyEights::TurnResult.from_json(json).as_json).to eq expected_hash
    end
  end

  def expected_hash
    {
      "card_played" => {
        "rank" => 'J',
        "suit" => 'Spades'
      },
      "cards_drawn" => [
        {
          "rank" => 'K',
          "suit" => 'Spades'
        },
        {
          "rank" => 'J',
          "suit" => 'Hearts'
        }
      ],
      "current_player" => {
        "name" => 'player',
        "id" => 0,
        "hand" => []
      },
      "wild_suit" => nil
    }
  end
end
