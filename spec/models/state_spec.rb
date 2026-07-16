require 'rails_helper'
RSpec.describe State, type: :model do
  it 'can find a country  and send its states in an array' do
    states = State.data.where(country_id: 'US')
    expected_size = 52
    expect(states.size).to eq expected_size
  end
end
