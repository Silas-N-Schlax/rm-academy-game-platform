require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'returns true if given valid input' do
      user = build(:user)
      expect(user).to be_valid
    end

    it 'returns false if name is not valid' do
      user = build(:user, name: nil)
      expect(user).to be_invalid
    end

    it 'returns false if email is not valid' do
      user = build(:user, email_address: 'test')
      expect(user).to be_invalid
    end

    it 'returns false if the password is invalid' do
      user = build(:user, password: nil)
      expect(user).to be_invalid
    end

    it 'returns false if the password is too short' do
      user = build(:user, password: '123')
      expect(user).to be_invalid
    end

    it 'returns false if the password is too long' do
      user = build(:user, password: '1234567891013829318972398724984')
      expect(user).to be_invalid
    end

    it 'returns false if password and confirm_password do not match' do
      user = build(:user, password: '123456')
      expect(user).to be_invalid
    end
  end
end
