require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#formatted_duration' do
    it 'formats a whole number of seconds as HH:MM:SS' do
      expected_output = '01:02:03'
      expect(helper.formatted_duration(3723)).to eq expected_output
    end

    it 'formats a duration over 24 hours without wrapping the hour count' do
      expected_output = '30:00:00'
      expect(helper.formatted_duration(30 * 3600)).to eq expected_output
    end

    it 'returns a dash for nil' do
      expected_output = '—'
      expect(helper.formatted_duration(nil)).to eq expected_output
    end

    it 'returns a dash for zero seconds' do
      expected_output = '—'
      expect(helper.formatted_duration(0)).to eq expected_output
    end
  end

  describe '#formatted_percentage' do
    it 'formats a float as N.N%' do
      expected_output = '70.5%'
      expect(helper.formatted_percentage(70.5)).to eq expected_output
    end

    it 'returns a dash for nil' do
      expected_output = '—'
      expect(helper.formatted_percentage(nil)).to eq expected_output
    end

    it 'returns a dash for zero' do
      expected_output = '—'
      expect(helper.formatted_percentage(0.0)).to eq expected_output
    end
  end

  describe '#formatted_count' do
    it 'formats a positive integer as a plain number' do
      expected_output = '5'
      expect(helper.formatted_count(5)).to eq expected_output
    end

    it 'returns a dash for zero' do
      expected_output = '—'
      expect(helper.formatted_count(0)).to eq expected_output
    end

    it 'returns a dash for nil' do
      expected_output = '—'
      expect(helper.formatted_count(nil)).to eq expected_output
    end
  end
end
