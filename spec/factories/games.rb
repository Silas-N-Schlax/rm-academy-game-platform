FactoryBot.define do
  factory :game do
    name { "RoleModel" }
    game_type { "Go Fish" }
    game_size { 2 }

    trait :game2 do
      name { "RockSolid" }
      game_type { "Go Fish" }
      game_size { 3 }
    end

    trait :no_name do
      name { nil }
    end

    trait :short_name do
      name { 'g' }
    end

    trait :invalid_game_type do
      game_type { 'Scythe' }
    end

    trait :no_game_size do
      game_size { nil }
    end

    trait :too_small do
      game_size { 1 }
    end

    trait :too_large  do
      game_size { 7 }
    end

    trait :waiting do
      started_at { nil }
      finished_at { nil }
    end

    trait :started do
      started_at { Time.new(2) }
      finished_at { nil }
    end

    trait :finished do
      started_at { Time.new(2) }
      finished_at { Time.new(3) }
    end

    factory :no_name_game, traits: [ :no_name ]
    factory :short_name_game, traits: [ :short_name ]
    factory :invalid_game_type_game, traits: [ :invalid_game_type ]
    factory :no_game_size_game, traits: [ :no_game_size ]
    factory :too_small_game, traits: [ :too_small ]
    factory :too_large_game, traits: [ :too_large ]
    factory :waiting_game, traits: [ :waiting ]
    factory :started_game, traits: [ :started ]
    factory :finished_game, traits: [ :finished ]
  end
end
