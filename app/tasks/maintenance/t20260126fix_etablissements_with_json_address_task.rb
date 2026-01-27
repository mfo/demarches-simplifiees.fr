# frozen_string_literal: true

module Maintenance
  # Fix etablissements where adresse contains a stringified Ruby hash
  # (starts with '{') instead of a proper inline address due to RNA service.
  # Re-enqueues EtablissementJob to fetch and format the address correctly.
  class T20260126fixEtablissementsWithJSONAddressTask < MaintenanceTasks::Task
    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    def collection
      Etablissement.where("adresse LIKE '{%'")
    end

    def process(etablissement)
      dossier = etablissement.dossier || etablissement.champ.dossier
      return if dossier.termine?

      procedure_id = dossier.procedure.id

      APIEntreprise::EtablissementJob.set(wait: rand(0..6.hours)).perform_later(etablissement.id, procedure_id)
    end

    def count
      collection.count
    end
  end
end
