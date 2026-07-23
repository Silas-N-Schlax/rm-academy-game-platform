FactoryBot.define do
  factory :turn, class: 'GoFishTurn' do
    trait :go_fish do
      rank { 'A' }
      player { nil }
      game { nil }
      user { nil }
    end

     trait :crazy_eights do
      rank { 'A' }
      suit { 'Spades' }
      request { nil }
      wild_suit { nil }
      game { nil }
      user { nil }
    end

    trait :rummy do
      action { 'draw' }
      source { 'stock' }
      card_ids { [] }
      meld_index { nil }
      game { nil }
      user { nil }
    end

    factory :crazy_eights_turn, class: 'CrazyEightsTurn', traits: [ :crazy_eights ]
    factory :go_fish_turn, class: 'GoFishTurn', traits: [ :go_fish ]
    factory :rummy_turn, class: 'RummyTurn', traits: [ :rummy ]
  end
end
