# frozen_string_literal: true

FactoryBot.define do
  factory :administrateurs_procedure do
    administrateur { Administrateur.find_by(user: { email: "admin@exemple.fr" }) }
    association :procedure
  end
end
