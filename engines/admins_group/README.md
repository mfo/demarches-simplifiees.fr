# Gestionnaire

Fonctionnalité « groupe gestionnaire » de demarche.numerique.gouv.fr, extraite
dans un engine parce qu’elle n’est utilisée que par certaines instances.

## Activation

`ADMINS_GROUP_ENABLED="enabled"` (voir `config/env.example.optional`), lu par
l’application hôte dans `config.ds_admins_group_enabled`. Sans ça, aucune route
n’est dessinée, le profil `:gestionnaire` n’existe pas et les écrans du manager
sont masqués.

## Tests

Les specs de la fonctionnalité sont taguées `:admins_group` automatiquement (voir
`spec/support/admins_group.rb` dans l’hôte) : le job CI qui rejoue la suite avec
la fonctionnalité coupée les ignore.
