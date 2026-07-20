# frozen_string_literal: true

def users.default_password = "this is a very complicated password !"

users.defaults password: users.default_password,
  confirmed_at: Time.zone.now,
  email_verified_at: Time.zone.now
