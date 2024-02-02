class AddAdministrateurIdToArchives < ActiveRecord::Migration[7.0]
  def change
    add_column :archives, :administrateur_id, :bigint
  end
end
