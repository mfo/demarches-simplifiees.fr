# frozen_string_literal: true

users.create :usager, email: "usager@exemple.fr"

admin = users.create :admin, email: "admin@exemple.fr"
admin.create_instructeur!
admin.create_administrateur!

instructeur = users.create :instructeur, email: "instructeur@exemple.fr"
instructeur.create_instructeur!

administrateurs.label default: admin.administrateur
instructeurs.label default: instructeur.instructeur
