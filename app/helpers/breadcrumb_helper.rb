# frozen_string_literal: true

module BreadcrumbHelper
  def breadcrumb_root_for(profile)
    case profile
    when :user
      [t('layouts.breadcrumb.root.user'), dossiers_path]
    when :instructeur
      [t('layouts.breadcrumb.root.instructeur'), instructeur_procedures_path]
    when :administrateur
      [t('layouts.breadcrumb.root.administrateur'), admin_procedures_path]
    when :expert
      [t('layouts.breadcrumb.root.expert'), expert_all_avis_path]
    when :gestionnaire
      [t('layouts.breadcrumb.root.gestionnaire'), gestionnaire_groupe_gestionnaires_path]
    else
      [t('layouts.breadcrumb.root.default'), root_path]
    end
  end
end
