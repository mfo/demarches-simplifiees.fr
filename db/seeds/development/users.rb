# frozen_string_literal: true

# Super-admin account for the manager interface, sharing the admin user's credentials.
SuperAdmin.create!(email: users.admin.email, password: users.default_password)

# Default instructeur automatically assigned by the platform (see DEFAULT_INSTRUCTEUR_EMAIL).
fixer = users.create email: ENV.fetch('DEFAULT_INSTRUCTEUR_EMAIL') { CONTACT_EMAIL },
  password: SecureRandom.base58(24)
fixer.create_instructeur!
