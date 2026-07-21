# frozen_string_literal: true

class CreateEmailTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :email_templates do |t|
      t.string :type, null: false
      t.references :procedure, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.string :subject
      t.text :body
      t.jsonb :json_subject
      t.jsonb :json_body
      t.timestamps
      t.index [:procedure_id, :type], unique: true
    end
  end
end
