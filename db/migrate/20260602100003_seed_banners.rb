# frozen_string_literal: true

class SeedBanners < ActiveRecord::Migration[7.2]
  def up
    safety_assured do
      %w[global instructeurs_only usagers_only login_page manager_login].each do |target|
        execute <<~SQL.squish
          INSERT INTO banners (target, created_at, updated_at)
          VALUES ('#{target}', NOW(), NOW())
          ON CONFLICT (target) DO NOTHING
        SQL
      end
    end
  end

  def down
    safety_assured do
      execute "DELETE FROM banners"
    end
  end
end
