# frozen_string_literal: true

class AddIndexOnNaf2025NullToEtablissements < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :etablissements, :naf_2025,
      where: "naf_2025 IS NULL",
      algorithm: :concurrently,
      name: :index_etablissements_on_naf_2025_null
  end
end
