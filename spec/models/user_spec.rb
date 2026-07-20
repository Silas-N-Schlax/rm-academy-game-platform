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
        create :user
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
    user = build :no_password_confirmation_user
      expect(user).to be_invalid
    end

    it 'returns false if password and password_confirmation do not match' do
      user = build :mismatching_passwords_user
      expect(user).to be_invalid
    end

    it 'returns true if updating name and passwords are not present' do
      user = create :user
      new_name = 'New Name'
      user.update({ name: new_name, email_address: user.email_address })
      expect(User.find(user.id).name).to eq new_name
    end
  end

  describe '#has_games?' do
    it 'returns true if user has games they can play' do
      game = create(:game)
      expect(game.users.first.has_games?).to be true
    end

    it 'returns false if all games are finished games' do
      game = create(:finished_game)
      expect(game.users.first.has_games?).to be false
    end
    it 'returns false if there are no games' do
      user = create :user
      expect(user.has_games?).to be false
    end
  end

  describe '#country_flag' do
    it 'returns country flag when country is present' do
      user = create(:user, country: 'US')
      expected_flag = '🇺🇸'
      expect(user.country_flag).to eq expected_flag
    end

    it 'returns country flag when county is present and is not the US' do
       user = create(:user, country: 'JP')
      expected_flag = '🇯🇵'
      expect(user.country_flag).to eq expected_flag
    end

    it 'returns nil when country is not present' do
      user = create :user
      expect(user.country_flag).to be_nil
    end
  end
end
