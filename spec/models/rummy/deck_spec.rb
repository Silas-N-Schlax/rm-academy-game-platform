require 'rails_helper'

RSpec.describe Rummy::Deck, type: :model do
  let(:card_class) { Rummy::Card }

  it_behaves_like "a CardGame::Deck"
  it_behaves_like "a CardGame::Pile"
end
