FactoryBot.define do
  factory :player do
    user
    game

    trait :winner do
      user
      game
      winner { true }
    end

    factory :player_as_winner, traits: [ :winner ]
  end
end
