# frozen_string_literal: true

FactoryBot.define do
  factory :referentiel do
    factory :csv_referentiel, class: 'Referentiels::CsvReferentiel' do
      name { 'referentiel.csv' }
      headers { ['option', 'calorie (kcal)', 'poids (g)'] }
      trait :with_items do
        after(:create) do |referentiel|
          create(:referentiel_item, referentiel:, data: { row: { 'option' => 'fromage', 'calorie_kcal' => '145', 'poids_g' => '60' } })
          create(:referentiel_item, referentiel:, data: { row: { 'option' => 'dessert', 'calorie_kcal' => '170', 'poids_g' => '70' } })
          create(:referentiel_item, referentiel:, data: { row: { 'option' => 'fruit', 'calorie_kcal' => '100', 'poids_g' => '50' } })
        end
      end
    end

    factory :api_referentiel, class: 'Referentiels::APIReferentiel' do
    end
  end

  trait :configured do
    url { 'https://rnb-api.beta.gouv.fr/api/alpha/buildings/{id}/' }
    mode { 'exact_match' }
    test_data { 'PG46YY6YWCX8' }
  end
end
