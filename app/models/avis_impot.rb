# frozen_string_literal: true

class AvisImpot
  include ActiveModel::Model
  include ActiveModel::Attributes

  # 2ddoc-specific
  attribute :two_ddoc, :boolean
  attribute :reference_avis, :string
  attribute :annee_des_revenus, :integer
  attribute :nombre_de_parts, :float
  attribute :declarant_1, :string
  attribute :declarant_1_numero_fiscal, :string
  attribute :declarant_2, :string
  attribute :declarant_2_numero_fiscal, :string
  attribute :revenu_fiscal_de_reference, :integer
  attribute :impot_revenu_net, :integer
  attribute :reste_a_payer, :integer
  attribute :retenue_a_la_source, :integer
  attribute :date_mise_en_recouvrement, :date

  # APIGeoService.parse_ban_address output
  attribute :label, :string
  attribute :type, :string
  attribute :street_address, :string
  attribute :street_number, :string
  attribute :street_name, :string
  attribute :postal_code, :string
  attribute :city_code, :string
  attribute :city_name, :string
  attribute :department_code, :string
  attribute :department_name, :string
  attribute :region_code, :string
  attribute :region_name, :string
  attribute :country_code, :string
  attribute :country_name, :string
end
