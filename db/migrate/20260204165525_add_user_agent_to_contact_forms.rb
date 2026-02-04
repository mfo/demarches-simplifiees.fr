# frozen_string_literal: true

class AddUserAgentToContactForms < ActiveRecord::Migration[7.2]
  def change
    add_column :contact_forms, :user_agent, :text
  end
end
