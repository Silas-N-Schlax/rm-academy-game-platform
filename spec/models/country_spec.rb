require 'rails_helper'
RSpec.describe Country, type: :model do
  it 'can find a country and return its details' do
    country = Country.data.find("US")
    expected_name = 'United States'
    expect(country.name).to eq expected_name
  end
end
