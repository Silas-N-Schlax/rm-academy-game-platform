require 'rails_helper'

RSpec.describe GoFish::TurnResult, type: :model do
  let(:results) do
    described_class.new(
      current_player: GoFish::Player.new(name: 'Player1'),
      opponent: GoFish::Player.new(name: 'Player2'),
      cards_taken: [],
      card_asked_for: 'K',
      card_picked_up: GoFish::Card.new('J'),
      goes_again: false
    )
  end
  let(:current) { 'Player1' }
  let(:opponent) { 'Player2' }

  describe '#question' do
    it 'returns the question that was asked' do
      expected_message = 'Player1 asked Player2 for any Ks'
      expect(results.question.join).to eq expected_message
    end
  end

  describe '#answer' do
    it 'returns the answer when the player does not have the card' do
      expected_message = 'Go Fish: Player2 didn\'t have any Ks'
      expect(results.answer).to eq expected_message
    end

    it 'returns the answer when the player does have the card' do
      expected_message = 'Player2 had 1 Ks'
      results.cards_taken = [ GoFish::Card.new('K') ]
      expect(results.answer).to eq expected_message
    end
  end

  describe '#go_fish' do
    context 'when its the current player' do
      context 'returns message telling player what they picked up' do
        it 'player gets what they wanted' do
          expected_message = 'You drew a J of Spades and do not get to go again'
          expect(results.go_fish(current)).to eq expected_message
        end
        it 'player does not get what they wanted' do
          results.goes_again = true
          expected_message = 'You drew a J of Spades and get to go again'
          expect(results.go_fish(current)).to eq expected_message
        end
      end
    end

    context 'when its the opponent' do
      it 'returns message when player gets what they wanted' do
        results.goes_again = true
        expected_message = 'Player1 drew a card and gets to go again'
        expect(results.go_fish(opponent)).to eq expected_message
      end

      it 'returns message when player did not get what they wanted' do
        expected_message = 'Player1 drew a card and does not get to go again'
        expect(results.go_fish(opponent)).to eq expected_message
      end

      it 'returns nil when player did not go fishing' do
        results.card_picked_up = nil
        expect(results.go_fish(opponent)).to be_nil
      end
    end
  end

  describe '#book_created' do
    before { results.created_book = GoFish::Book.new('J') }
    it 'returns message for current player that a book has been created' do
      expected_message = 'You created a book of Js'
      expect(results.book_created(current)).to eq expected_message
    end

    it 'returns message for all players that a book has been created' do
      expected_message = 'Player1 created a book of Js'
      expect(results.book_created(opponent)).to eq expected_message
    end

    it 'returns nil when a player did not create a book with the book' do
      results.created_book = nil
      expect(results.book_created(current)).to be_nil
    end
  end

  describe '#as_json' do
    let(:expected_hash) do
      {
        "current_player" => {
          "name" => 'Player1',
          "id" => 0,
          "books" => [],
          "hand" => []
        },
        "opponent" => {
          "name" => 'Player2',
          "id" => 0,
          "books" => [],
          "hand" => []
        },
        "cards_taken" => [],
        "card_asked_for" => "K",
        "card_picked_up" => {
          "rank" => "J",
          "suit" => "Spades"
        },
        "goes_again" => false,
        "created_book" => nil,
        "got_card" => []
      }
    end
     it 'returns expected hash' do
      expect(results.as_json).to eq expected_hash
    end
  end

  describe '.from_json' do
    it 'restores current state of the player' do
      json = results.as_json
      result = GoFish::TurnResult.from_json(json)
      expect(result.as_json).to eq json
    end
  end

  describe '#add_got_card_record' do
    let(:player) { GoFish::Player.new(name: 'Player1') }
    let(:card) { GoFish::Card.new('J') }
    before { results.add_got_card_record(player, card) }
    it 'adds record to array' do
      expected_size = 1
      got_card = results.got_card.first
      expect(results.got_card.size).to eq expected_size
      expect(got_card.first).to eq player
      expect(got_card.last).to eq card
    end
  end

  describe '#got_card_message' do
    let(:player1) { GoFish::Player.new(name: 'Player1') }
    let(:player2) { GoFish::Player.new(name: 'Player2') }
    let(:card1) { GoFish::Card.new('K') }
    let(:card2) { GoFish::Card.new('J') }
    let(:expected_message1) { 'You ran out of cards, you drew a K' }
    let(:expected_message2) { 'Player1 ran out of cards, they drew a card' }
    before { results.add_got_card_record(player1, card1) }
    context 'when one player gets a card' do
      it 'returns an array with one message' do
        result = results.got_card_message(player1.name)
        expected_size = 1
        expect(result.size).to eq expected_size
        expect(result.first).to eq expected_message1
      end
    end
    context 'when two players get a card' do
      before { results.add_got_card_record(player2, card2) }
      it 'returns an array with two messages' do
        result1 = results.got_card_message(player1.name)
        result2 = results.got_card_message(player2.name)
        expected_size = 2
        expect(result1.size).to eq expected_size
        expect(result1.first).to eq expected_message1
        expect(result2.first).to eq expected_message2
      end
    end
  end
end
