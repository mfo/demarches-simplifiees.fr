# frozen_string_literal: true

class AddNaf2025ToEtablissements < ActiveRecord::Migration[7.2]
  def change
    add_column :etablissements, :naf_2025, :string
    add_column :etablissements, :libelle_naf_2025, :string
  end
end
