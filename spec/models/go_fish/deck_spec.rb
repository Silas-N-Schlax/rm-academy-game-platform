require 'rails_helper'

RSpec.describe GoFish::Deck, type: :model do
  let(:card_class) { GoFish::Card }

  it_behaves_like "a CardGame::Deck"
  it_behaves_like "a CardGame::Pile"
end
