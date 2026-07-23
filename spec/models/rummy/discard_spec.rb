require 'rails_helper'

RSpec.describe Rummy::Discard, type: :model do
  let(:card_class) { Rummy::Card }

  it_behaves_like "a CardGame::Pile"
end
