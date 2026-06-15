# frozen_string_literal: true

class CreateBanners < ActiveRecord::Migration[7.2]
  def change
    create_table :banners do |t|
      t.string :target, null: false
      t.text :content
      t.timestamps
    end
  end
end
