# frozen_string_literal: true

users.create :usager, email: "usager@exemple.fr"

admin = users.create :admin, email: "admin@exemple.fr"
admin.create_instructeur!(bypass_email_login_token: true)
admin.create_administrateur!

instructeur = users.create :instructeur, email: "instructeur@exemple.fr"
instructeur.create_instructeur!(bypass_email_login_token: true)

# An administrateur guaranteed to own nothing — no procedures, no services, no
# API tokens. For specs whose subject is the admin's own aggregate state
# (deletion, merge, unused, token scoping); seeds must never attach anything
# to it.
blank_admin = users.create :blank_admin, email: "blank-admin@exemple.fr"
blank_admin.create_administrateur!

administrateurs.label default: admin.administrateur, blank: blank_admin.administrateur
instructeurs.label default: instructeur.instructeur, admin: admin.instructeur
