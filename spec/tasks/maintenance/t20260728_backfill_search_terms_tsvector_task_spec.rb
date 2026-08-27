# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260728BackfillSearchTermsTsvectorTask do
    let(:dossier) { create(:dossier, state: :en_construction) }

    # Simulate a row indexed before the tsvector columns existed.
    def clear_tsvectors!(text: 'Hélène pommes', private_text: 'annotations')
      Dossier.where(id: dossier.id).update_all(
        Dossier.sanitize_sql_array([
          "search_terms = :text, private_search_terms = :private_text, search_terms_tsvector = NULL, all_search_terms_tsvector = NULL",
          text:, private_text:,
        ])
      )
    end

    def collected?
      described_class.new.collection.any? { _1.ids.include?(dossier.id) }
    end

    def backfill!
      described_class.new.process(Dossier.where(id: dossier.id))
    end

    def match?(column, query)
      Dossier.connection.select_value(
        Dossier.sanitize_sql_array([
          "SELECT #{column} @@ to_tsquery('french_unaccent', :query) FROM dossiers WHERE id = :id",
          query:, id: dossier.id,
        ])
      )
    end

    describe "#collection" do
      it "only picks up rows without a stored tsvector" do
        perform_enqueued_jobs(only: DossierIndexSearchTermsJob)
        expect(collected?).to be(false)

        clear_tsvectors!
        expect(collected?).to be(true)
      end
    end

    describe "#process" do
      it "computes both vectors from the text columns" do
        clear_tsvectors!
        backfill!

        expect(match?('search_terms_tsvector', 'helene:*')).to be(true)
        # annotations stay out of the default vector
        expect(match?('search_terms_tsvector', 'annotations:*')).to be(false)
        # and the combined vector matches terms spanning both parts
        expect(match?('all_search_terms_tsvector', 'pommes:* & annotations:*')).to be(true)
      end

      it "leaves never-indexed rows with an empty vector rather than NULL" do
        Dossier.where(id: dossier.id).update_all(
          "search_terms = NULL, private_search_terms = NULL, search_terms_tsvector = NULL, all_search_terms_tsvector = NULL"
        )
        backfill!

        expect(collected?).to be(false)
        expect(match?('search_terms_tsvector', 'helene:*')).to be(false)
      end
    end
  end
end
