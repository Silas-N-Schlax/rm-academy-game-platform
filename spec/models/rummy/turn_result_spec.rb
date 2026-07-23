require 'rails_helper'

RSpec.describe Rummy::TurnResult, type: :model do
  let(:player) { Rummy::Player.new(name: 'Alex', id: 1) }
  let(:other_id) { 2 }

  describe '#feed_lines' do
    context 'when drawing from the stock' do
      let(:result) { described_class.new(current_player: player, draw_source: 'stock', card_drawn: Rummy::Card.new('7', 'Hearts')) }

      it 'reveals the drawn card to the drawer' do
        expect(result.feed_lines(player.id)).to eq [ 'You drew the 7 of Hearts from the stock.' ]
      end

      it 'hides the drawn card from everyone else' do
        expect(result.feed_lines(other_id)).to eq [ 'Alex drew a card from the stock.' ]
      end
    end

    context 'when drawing from the discard pile' do
      let(:result) { described_class.new(current_player: player, draw_source: 'discard', card_drawn: Rummy::Card.new('K', 'Spades')) }

      it 'shows the drawn card to everyone, since the discard pile is public' do
        expect(result.feed_lines(player.id)).to eq [ 'You drew the King of Spades from the discard pile.' ]
        expect(result.feed_lines(other_id)).to eq [ 'Alex drew the King of Spades from the discard pile.' ]
      end
    end

    context 'when no draw was possible' do
      let(:result) { described_class.new(current_player: player, draw_source: 'none') }

      it 'says nothing was available to draw' do
        expect(result.feed_lines(player.id)).to eq [ 'You had nothing to draw — stock and discard were both empty.' ]
        expect(result.feed_lines(other_id)).to eq [ 'Alex had nothing to draw — stock and discard were both empty.' ]
      end
    end

    context 'when the draw triggered a stock recycle' do
      let(:result) do
        described_class.new(current_player: player, draw_source: 'stock', card_drawn: Rummy::Card.new('7', 'Hearts'), recycled_stock: true)
      end

      it 'notes the recycle for every viewer, after the draw line' do
        expect(result.feed_lines(other_id)).to eq [
          'Alex drew a card from the stock.',
          'The stock ran out, so the discard pile (except its top card) was reshuffled into a new stock.'
        ]
      end
    end

    context 'when a meld was laid down' do
      let(:meld) { Rummy::Meld.new(cards: [ Rummy::Card.new('K', 'Spades'), Rummy::Card.new('K', 'Hearts'), Rummy::Card.new('K', 'Diamonds') ]) }
      let(:result) { described_class.new(current_player: player, melds_laid_down: [ meld ]) }

      it 'describes the meld for the actor' do
        expect(result.feed_lines(player.id)).to eq [ 'You melded three Kings.' ]
      end

      it 'describes the meld for everyone else' do
        expect(result.feed_lines(other_id)).to eq [ 'Alex melded three Kings.' ]
      end

      it 'prefixes a run meld with the article "a", not doubling up with the meld-onto phrasing' do
        run_meld = Rummy::Meld.new(cards: [ Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts'), Rummy::Card.new('7', 'Hearts') ])
        run_result = described_class.new(current_player: player, melds_laid_down: [ run_meld ])
        expect(run_result.feed_lines(player.id)).to eq [ 'You melded a run of 5-6-7 of Hearts.' ]
      end
    end

    context 'when a card was laid off onto an existing meld' do
      let(:meld) { Rummy::Meld.new(cards: [ Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts'), Rummy::Card.new('7', 'Hearts') ]) }
      let(:result) { described_class.new(current_player: player, lay_offs: [ { meld: meld, cards: [ Rummy::Card.new('8', 'Hearts') ] } ]) }

      it 'names the card and the meld it joined' do
        expect(result.feed_lines(player.id)).to eq [ 'You laid off the 8 of Hearts onto the run of 5-6-7 of Hearts.' ]
      end
    end

    context 'when a card was discarded' do
      let(:result) { described_class.new(current_player: player, card_discarded: Rummy::Card.new('Q', 'Clubs')) }

      it 'names the discarded card' do
        expect(result.feed_lines(player.id)).to eq [ 'You discarded the Queen of Clubs.' ]
        expect(result.feed_lines(other_id)).to eq [ 'Alex discarded the Queen of Clubs.' ]
      end
    end

    context 'when the player went out' do
      let(:result) { described_class.new(current_player: player, went_out: true) }

      it 'announces the win' do
        expect(result.feed_lines(player.id)).to eq [ 'You went out and won the game!' ]
        expect(result.feed_lines(other_id)).to eq [ 'Alex went out and won the game!' ]
      end
    end

    context 'for a full turn combining several steps' do
      let(:meld) { Rummy::Meld.new(cards: [ Rummy::Card.new('7', 'Spades'), Rummy::Card.new('7', 'Hearts'), Rummy::Card.new('7', 'Diamonds') ]) }
      let(:result) do
        described_class.new(
          current_player: player,
          draw_source: 'stock',
          card_drawn: Rummy::Card.new('2', 'Clubs'),
          melds_laid_down: [ meld ],
          card_discarded: Rummy::Card.new('2', 'Clubs'),
          went_out: true
        )
      end

      it 'orders the lines draw, meld, discard, went-out' do
        expect(result.feed_lines(player.id)).to eq [
          'You drew the 2 of Clubs from the stock.',
          'You melded three 7s.',
          'You discarded the 2 of Clubs.',
          'You went out and won the game!'
        ]
      end
    end
  end

  describe '#as_json / .from_json' do
    let(:meld) { Rummy::Meld.new(cards: [ Rummy::Card.new('K', 'Spades'), Rummy::Card.new('K', 'Hearts'), Rummy::Card.new('K', 'Diamonds') ]) }
    let(:layoff_meld) { Rummy::Meld.new(cards: [ Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts'), Rummy::Card.new('7', 'Hearts') ]) }
    let(:result) do
      described_class.new(
        current_player: player,
        draw_source: 'stock',
        card_drawn: Rummy::Card.new('2', 'Clubs'),
        recycled_stock: true,
        melds_laid_down: [ meld ],
        lay_offs: [ { meld: layoff_meld, cards: [ Rummy::Card.new('8', 'Hearts') ] } ],
        card_discarded: Rummy::Card.new('3', 'Diamonds'),
        went_out: true
      )
    end

    it 'round-trips every attribute through JSON' do
      restored = described_class.from_json(result.as_json)

      expect(restored.feed_lines(player.id)).to eq result.feed_lines(player.id)
    end
  end
end
