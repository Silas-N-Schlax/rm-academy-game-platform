require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'returns true if given valid input' do
      user = build :user
      expect(user).to be_valid
    end

    it 'allow 2 users to join' do
      expect do
        create :user
        create :user2
      end.to change(User, :count).by 2
    end

    it 'returns false if name is not valid' do
      user = build :no_name_user
      expect(user).to be_invalid
    end

    it 'returns false if no email' do
      user = build :no_email_user
      expect(user).to be_invalid
    end

    it 'returns false if email is not valid' do
      user = build :invalid_email_user
      expect(user).to be_invalid
    end

    it 'returns false if the password is invalid' do
      user = build :no_password_user
      expect(user).to be_invalid
    end

    it 'returns false if the password is too short' do
      user = build :short_password_user
      expect(user).to be_invalid
    end

    it 'returns false if the password is too long' do
      user = build :long_password_user
      expect(user).to be_invalid
    end

    it 'returns false if no confirm password' do
    user = build :no_confirm_password_user
      expect(user).to be_invalid
    end

    it 'returns false if password and confirm_password do not match' do
      user = build :mismatching_passwords_user
      expect(user).to be_invalid
    end
  end
end
