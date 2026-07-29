require 'rails_helper'

RSpec.describe PerPageClampable do
  let(:dummy_class) do
    Class.new { include PerPageClampable }.tap do |klass|
      klass.const_set(:PER_PAGE_OPTIONS, [ 10, 25, 50, 100 ].freeze)
      klass.const_set(:DEFAULT_PER_PAGE, 50)
    end
  end

  it 'clamps a value below the lowest option up to it' do
    expect(dummy_class.clamp_per_page(1)).to eq 10
  end

  it 'clamps a value above the highest option down to it' do
    expect(dummy_class.clamp_per_page(500)).to eq 100
  end

  it 'leaves an in-range value unchanged' do
    expect(dummy_class.clamp_per_page(39)).to eq 39
  end

  it 'defaults to the class default when given a blank value' do
    expect(dummy_class.clamp_per_page(nil)).to eq 50
  end
end
