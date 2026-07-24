require 'rails_helper'

RSpec.describe Rummy::TurnResult, type: :model do
  let(:player) { Rummy::Player.new(name: 'Alex', id: 1) }
  let(:other_id) { 2 }

  describe '#feed_lines' do
    context 'when drawing from the stock' do
      let(:result) { described_class.new(current_player: player, draw_source: 'stock', card_drawn: Rummy::Card.new('7', 'Hearts')) }

      it 'reveals the drawn card to the drawer' do
        expect(result.feed_lines(player.id)).to eq [ { text: 'Drew the 7 of Hearts from the stock', kind: :draw } ]
      end

      it 'hides the drawn card from everyone else' do
        expect(result.feed_lines(other_id)).to eq [ { text: 'Drew a card from the stock', kind: :draw } ]
      end
    end

    context 'when drawing from the discard pile' do
      let(:result) { described_class.new(current_player: player, draw_source: 'discard', card_drawn: Rummy::Card.new('K', 'Spades')) }

      it 'shows the drawn card to everyone, since the discard pile is public' do
        expect(result.feed_lines(player.id)).to eq [ { text: 'Drew the King of Spades from the discard pile', kind: :draw } ]
        expect(result.feed_lines(other_id)).to eq [ { text: 'Drew the King of Spades from the discard pile', kind: :draw } ]
      end
    end

    context 'when no draw was possible' do
      let(:result) { described_class.new(current_player: player, draw_source: 'none') }

      it 'says nothing was available to draw' do
        expect(result.feed_lines(player.id)).to eq [
          { text: 'Had nothing to draw — stock and discard were both empty', kind: :draw }
        ]
      end
    end

    context 'when the draw triggered a stock recycle' do
      let(:result) do
        described_class.new(current_player: player, draw_source: 'stock', card_drawn: Rummy::Card.new('7', 'Hearts'), recycled_stock: true)
      end

      it 'notes the recycle for every viewer, after the draw line' do
        expect(result.feed_lines(other_id)).to eq [
          { text: 'Drew a card from the stock', kind: :draw },
          { text: 'The stock ran out, so the discard pile (except its top card) was reshuffled into a new stock', kind: :recycle }
        ]
      end
    end

    context 'when a meld was laid down' do
      let(:meld) { Rummy::Meld.new(cards: [ Rummy::Card.new('K', 'Spades'), Rummy::Card.new('K', 'Hearts'), Rummy::Card.new('K', 'Diamonds') ]) }
      let(:result) { described_class.new(current_player: player, melds_laid_down: [ meld ]) }

      it 'describes the meld' do
        expect(result.feed_lines(player.id)).to eq [ { text: 'Melded three Kings', kind: :meld } ]
      end

      it 'prefixes a run meld with the article "a", not doubling up with the meld-onto phrasing' do
        run_meld = Rummy::Meld.new(cards: [ Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts'), Rummy::Card.new('7', 'Hearts') ])
        run_result = described_class.new(current_player: player, melds_laid_down: [ run_meld ])
        expect(run_result.feed_lines(player.id)).to eq [ { text: 'Melded a run of 5-6-7 of Hearts', kind: :meld } ]
      end
    end

    context 'when a card was laid off onto an existing meld' do
      let(:meld) { Rummy::Meld.new(cards: [ Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts'), Rummy::Card.new('7', 'Hearts') ]) }
      let(:result) { described_class.new(current_player: player, lay_offs: [ { meld: meld, cards: [ Rummy::Card.new('8', 'Hearts') ] } ]) }

      it 'names the card and the meld it joined' do
        expect(result.feed_lines(player.id)).to eq [
          { text: 'Laid off the 8 of Hearts onto the run of 5-6-7 of Hearts', kind: :lay_off }
        ]
      end
    end

    context 'when a card was discarded' do
      let(:result) { described_class.new(current_player: player, card_discarded: Rummy::Card.new('Q', 'Clubs')) }

      it 'names the discarded card' do
        expect(result.feed_lines(player.id)).to eq [ { text: 'Discarded the Queen of Clubs', kind: :discard } ]
      end
    end

    context 'when the player went out' do
      let(:result) { described_class.new(current_player: player, went_out: true) }

      it 'announces the win' do
        expect(result.feed_lines(player.id)).to eq [ { text: 'Went out and won the game!', kind: :win } ]
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
          { text: 'Drew the 2 of Clubs from the stock', kind: :draw },
          { text: 'Melded three 7s', kind: :meld },
          { text: 'Discarded the 2 of Clubs', kind: :discard },
          { text: 'Went out and won the game!', kind: :win }
        ]
      end
    end
  end

  describe '#actor_label' do
    let(:result) { described_class.new(current_player: player) }

    it 'returns "You" for the acting player and the player name for everyone else' do
      expect(result.actor_label(player.id)).to eq 'You'
      expect(result.actor_label(other_id)).to eq 'Alex'
    end
  end

  describe '#as_json / .from_json' do
    let(:meld) { Rummy::Meld.new(cards: [ Rummy::Card.new('K', 'Spades'), Rummy::Card.new('K', 'Hearts'), Rummy::Card.new('K', 'Diamonds') ]) }
    let(:layoff_meld) { Rummy::Meld.new(cards: [ Rummy::Card.new('5', 'Hearts'), Rummy::Card.new('6', 'Hearts'), Rummy::Card.new('7', 'Hearts') ]) }
    let(:occurred_at) { Time.zone.parse('2024-01-01 12:00:00') }
    let(:result) do
      described_class.new(
        current_player: player,
        draw_source: 'stock',
        card_drawn: Rummy::Card.new('2', 'Clubs'),
        recycled_stock: true,
        melds_laid_down: [ meld ],
        lay_offs: [ { meld: layoff_meld, cards: [ Rummy::Card.new('8', 'Hearts') ] } ],
        card_discarded: Rummy::Card.new('3', 'Diamonds'),
        went_out: true,
        occurred_at: occurred_at
      )
    end

    it 'round-trips every attribute through JSON' do
      restored = described_class.from_json(result.as_json)

      expect(restored.feed_lines(player.id)).to eq result.feed_lines(player.id)
      expect(restored.occurred_at).to eq occurred_at
    end
  end
end
