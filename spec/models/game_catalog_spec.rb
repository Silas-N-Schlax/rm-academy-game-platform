require 'rails_helper'

RSpec.describe GameCatalog, type: :model do
  it 'returns both games' do
    expect(GameCatalog.data.all.map(&:id)).to contain_exactly('go-fish', 'crazy-eights')
  end

  it 'finds a game by slug and returns its details, including sections and type' do
    game = GameCatalog.data.find!('crazy-eights')
    expect(game.name).to eq 'Crazy Eights'
    expect(game.sections).not_to be_empty
    expect(game.game_type).to eq 'Card Game'
  end

  it 'raises when the slug is unknown' do
    expect { GameCatalog.data.find!('checkers') }.to raise_error(DataFor::RecordNotFound)
  end

  it 'uses the slug as the url param' do
    game = GameCatalog.data.find!('go-fish')
    expect(game.to_param).to eq 'go-fish'
  end
end
