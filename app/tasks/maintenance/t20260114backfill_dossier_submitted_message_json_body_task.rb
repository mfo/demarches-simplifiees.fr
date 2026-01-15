# frozen_string_literal: true

module Maintenance
  class T20260114backfillDossierSubmittedMessageJSONBodyTask < MaintenanceTasks::Task
    # Convertit les messages de fin de dépôt existants (texte simple)
    # vers le format JSON TipTap pour supporter le formatage riche.

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    def collection
      DossierSubmittedMessage.where(json_body: nil).where.not(message_on_submit_by_usager: [nil, ''])
    end

    def process(dsm)
      dsm.update!(json_body: dsm.send(:plain_text_to_tiptap_json, dsm.message_on_submit_by_usager))
    end

    def count
      collection.count
    end
  end
end
