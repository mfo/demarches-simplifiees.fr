# frozen_string_literal: true

class AddDeletableToCommentaires < ActiveRecord::Migration[8.0]
  def change
    add_column :commentaires, :deletable, :boolean, default: true, null: false
  end
end
