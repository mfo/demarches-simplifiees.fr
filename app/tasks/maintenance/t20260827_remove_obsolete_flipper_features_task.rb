# frozen_string_literal: true

module Maintenance
  class T20260827RemoveObsoleteFlipperFeaturesTask < MaintenanceTasks::Task
    # Retirer un flag de config/initializers/flipper.rb ne le supprime pas de la
    # base : setup_features ne calcule que `features - existing` et n'appelle que
    # Flipper.add. Les lignes s'accumulent donc dans flipper_features et restent
    # affichées aux opérateurs dans /manager/features, sans rien piloter.
    #
    # Les clés ci-dessous ont été relevées en production et confrontées au code :
    # aucune n'y apparaît plus (vérifié au symbole entier, pas en sous-chaîne).
    #
    #   agent_connect_2fa              9f2979a563  2025-03-17
    #   referentiel_type_de_champ      43470dae8d  2026-02-26
    #   ocr                            e7b0017f76  2026-03-02
    #   analyse_justificatif_domicile  1f5194ef6a  2026-07-06
    #   export_avec_horodatage         607cc40a81  2026-08-25  (#13717)
    #   api_entreprise_tva_job         010a7a57ef  2026-08-26
    #   team_on_strike                 2c418f63a8  2020-09-14
    #
    # Attention : la fonctionnalité OCR n'est pas concernée. Elle vit toujours via
    # OcrService et la colonne active_storage_blobs.ocr ; seul le flag est mort.
    #
    # export_with_horodatage est le nom mal orthographié que le code lisait avant
    # #13717. Absent de la production, mais présent en développement, où la lecture
    # a créé la ligne. On le nettoie aussi pour aligner les autres instances.
    #
    # Flipper.remove supprime la feature et tous ses gates via l'adaptateur
    # configuré. L'opération est idempotente : une clé absente n'est pas une erreur.

    include RunnableOnDeployConcern

    run_on_first_deploy

    OBSOLETE_FEATURES = [
      :team_on_strike,
      :agent_connect_2fa,
      :referentiel_type_de_champ,
      :ocr,
      :analyse_justificatif_domicile,
      :export_avec_horodatage,
      :export_with_horodatage,
      :api_entreprise_tva_job,
    ].freeze

    def collection
      OBSOLETE_FEATURES
    end

    def process(feature_key)
      Flipper.remove(feature_key)
    end
  end
end
