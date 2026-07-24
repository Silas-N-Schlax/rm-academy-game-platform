require 'rails_helper'

RSpec.describe GameBoardFeedHelper, type: :helper do
  describe '#feed_line_class' do
    it 'is the notable modifier for a meld or lay-off line' do
      expect(helper.feed_line_class(:meld)).to eq 'feed-drawer__line--notable'
      expect(helper.feed_line_class(:lay_off)).to eq 'feed-drawer__line--notable'
    end

    it 'is the climax modifier for a win line' do
      expect(helper.feed_line_class(:win)).to eq 'feed-drawer__line--climax'
    end

    it 'is nil for routine lines' do
      expect(helper.feed_line_class(:draw)).to be_nil
      expect(helper.feed_line_class(:discard)).to be_nil
      expect(helper.feed_line_class(:recycle)).to be_nil
    end
  end

  describe '#feed_line_text' do
    it 'adds a trophy to a win line' do
      expect(helper.feed_line_text(text: 'Went out and won the game!', kind: :win)).to eq '🏆 Went out and won the game!'
    end

    it 'leaves other lines unchanged' do
      expect(helper.feed_line_text(text: 'Discarded the Queen of Clubs', kind: :discard)).to eq 'Discarded the Queen of Clubs'
    end
  end
end
