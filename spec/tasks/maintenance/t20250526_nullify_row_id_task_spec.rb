# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20250526NullifyRowIdTask do
    describe "#process" do
      subject(:process) { described_class.process(dossier) }
      let(:procedure) { create(:procedure, public_type_de_champs: [{}, { type: :repetition, children: [{ type: :text }] }]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:champs_with_null_row_id) { dossier.champ_data.where(row_id: [nil, 'N']) }

      before do
        dossier.champ_data.where(row_id: nil).update_all(row_id: 'N')
      end

      def null_row_id_counts
        champs_with_null_row_id.pluck(:row_id)
          .partition(&:nil?)
          .map(&:size)
      end

      it 'nullify row_id' do
        expect { process }. to change { null_row_id_counts }.from([0, 1]).to([1, 0])
      end

      context 'deal with conflicts' do
        before do
          attributes = dossier.champ_data.where(row_id: 'N').first.attributes
          dossier.champ_data.create(attributes.merge(row_id: nil, id: nil))
        end
        it 'nullify row_id' do
          expect { process }. to change { null_row_id_counts }.from([1, 1]).to([1, 0])
        end
      end
    end
  end
end
