FactoryBot.define do
  factory :turn, class: 'GoFishTurn' do
    rank { 'A' }
    player { nil }
    game_id { nil }
    user_id { nil }
  end
end
