# frozen_string_literal: true

class DropMoreIgnoredColumns < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      remove_column :avis, :email, :string
      remove_column :champs, :parent_id, :bigint
      remove_column :champs, :type_de_champ_id, :integer
      remove_column :dossiers, :editing_fork_origin_id, :bigint
      remove_column :dossiers, :last_champ_piece_jointe_updated_at, :datetime
      remove_column :export_templates, :content, :jsonb, default: {}
      remove_column :exports, :procedure_presentation_snapshot, :jsonb
      remove_column :procedure_presentations, :displayed_fields, :jsonb, default: [{ "label" => "Demandeur", "table" => "user", "column" => "email" }], null: false
      remove_column :procedure_presentations, :filters, :jsonb, default: { "tous" => [], "suivis" => [], "traites" => [], "a-suivre" => [], "archives" => [], "expirant" => [], "supprimes" => [] }, null: false
      remove_column :procedure_presentations, :sort, :jsonb, default: { "order" => "desc", "table" => "notifications", "column" => "notifications" }, null: false
      remove_column :procedures, :api_entreprise_token_expires_at, :datetime, precision: nil
      remove_column :procedures, :path, :string
      remove_column :procedures, :pro_connect_restricted, :boolean, default: false, null: false
      remove_column :referentiels, :test_data, :string
      remove_column :referentiels, :url, :string
      remove_column :referentiels, :use_tiptap, :boolean, default: true, null: false
    end
  end
end
