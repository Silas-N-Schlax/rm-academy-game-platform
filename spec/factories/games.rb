FactoryBot.define do
  factory :game do
    sequence(:name) { |n| "RoleModel#{n}" }
    type { "GoFishGame" }
    game_size { 2 }
    initialize_with { type.present? ? type.constantize.new(attributes) : Game.new(attributes) }

    transient do
      player_count { 2 }
    end

    after(:create) do |game, evaluator|
      create_list(:player, evaluator.player_count, game: game)
    end

    trait :game2 do
      name { "RockSolid" }
      type { "GoFishGame" }
      game_size { 3 }
    end

    trait :no_name do
      name { nil }
    end

    trait :short_name do
      name { 'g' }
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

    trait :archived do
      archived_at { Time.current }
    end

    trait :stale do
      updated_at { 3.days.ago }
    end

    factory :no_name_game, traits: [ :no_name ]
    factory :short_name_game, traits: [ :short_name ]
    factory :no_game_size_game, traits: [ :no_game_size ]
    factory :too_small_game, traits: [ :too_small ]
    factory :too_large_game, traits: [ :too_large ]
    factory :waiting_game, traits: [ :waiting ]
    factory :started_game, traits: [ :started ]
    factory :finished_game, traits: [ :finished ]
    factory :archived_game, traits: [ :archived, :finished ]
    factory :stale_game, traits: [ :stale ]
  end
end
