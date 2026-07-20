FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User#{n}" }
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password" }
    password_confirmation { "password" }
    # street_address { '123 example St' }
    # country { 'US' }
    # state { "NC" }
    # city { "Raleigh" }
    # zip_code { 00000 }

    trait :user2 do
      name { "player2" }
      email_address { "user2@example.com" }
      password { "password2" }
      password_confirmation { "password2" }
    end

    trait :no_name do
      name { nil }
    end

    trait :no_email do
      email_address { nil }
    end

    trait :invalid_email do
      email_address { "bob" }
    end

    trait :no_password do
      password { nil }
    end

    trait :short_password do
      password { 'pas' }
    end

    trait :long_password do
      password { 'ThisIsASuperLongPasswordItIsSoSafe' }
    end

    trait :no_password_confirmation do
      password_confirmation { nil }
    end

    trait :mismatching_passwords do
      password { 'password' }
      password_confirmation { 'confirm' }
    end

    factory :user2, traits: [ :user2 ]
    factory :no_name_user, traits: [ :no_name ]
    factory :no_email_user, traits: [ :no_email ]
    factory :invalid_email_user, traits: [ :invalid_email ]
    factory :no_password_user, traits: [ :no_password ]
    factory :short_password_user, traits: [ :short_password ]
    factory :long_password_user, traits: [ :long_password ]
    factory :no_password_confirmation_user, traits: [ :no_password_confirmation ]
    factory :mismatching_passwords_user, traits: [ :mismatching_passwords ]
  end
end
