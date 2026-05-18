# frozen_string_literal: true

class RemoveLegacyOtpColumnsFromSuperAdmins < ActiveRecord::Migration[7.2]
  def up
    safety_assured do
      remove_column :super_admins, :encrypted_otp_secret
      remove_column :super_admins, :encrypted_otp_secret_iv
      remove_column :super_admins, :encrypted_otp_secret_salt
    end
  end

  def down
    add_column :super_admins, :encrypted_otp_secret, :string
    add_column :super_admins, :encrypted_otp_secret_iv, :string
    add_column :super_admins, :encrypted_otp_secret_salt, :string
  end
end
