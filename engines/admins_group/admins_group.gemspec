# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name    = 'admins_group'
  spec.version = '0.1.0'
  spec.authors = ['La Suite numérique']
  spec.summary = 'Groupes gestionnaires : gestion d’administrateurs par groupe'
  spec.description = <<~DESC
    Fonctionnalité « groupe gestionnaire », activée par instance via
    ADMINS_GROUP_ENABLED. Elle permet à des gestionnaires d’administrer des
    groupes d’administrateurs, organisés en arborescence, avec une messagerie
    entre un groupe et ses administrateurs.
  DESC
  spec.license = 'AGPL-3.0'

  spec.files = Dir['{app,config,lib}/**/*', 'README.md']

  spec.required_ruby_version = '>= 3.4.0'

  spec.add_dependency 'ancestry'
  spec.add_dependency 'rails', '>= 8.1'
end
