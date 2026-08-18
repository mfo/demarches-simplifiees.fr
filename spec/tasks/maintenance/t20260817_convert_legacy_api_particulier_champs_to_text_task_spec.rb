# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260817ConvertLegacyAPIParticulierChampsToTextTask do
    let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :text }]) }
    let(:type_de_champ) { procedure.published_revision.types_de_champ.first }
    let(:dossier) { create(:dossier, :en_construction, :with_populated_champs, procedure:) }
    let(:champ) { dossier.champ_data.first }
    let(:cnaf_data) { { 'quotient_familial' => { 'quotientFamilial' => 1234 } } }

    before do
      champ.update_columns(
        type: 'Champs::CnafChamp',
        value: nil,
        external_id: { numero_allocataire: '1234567', code_postal: '75001' }.to_json,
        external_state: 'fetched',
        data: cnaf_data
      )
      type_de_champ.update_columns(type_champ: 'cnaf')
    end

    # the enum casts unknown values to nil, read the column as stored
    def raw_type_champ
      TypeDeChamp.connection.select_value("SELECT type_champ FROM types_de_champ WHERE id = #{type_de_champ.id}")
    end

    describe "#collection" do
      it "returns the ids of the legacy types de champ" do
        expect(described_class.new.collection).to contain_exactly([type_de_champ.id, type_de_champ.stable_id])
      end
    end

    describe "#process" do
      subject(:process) { described_class.process([type_de_champ.id, type_de_champ.stable_id]) }

      it "converts the type de champ to text" do
        expect { process }.to change { raw_type_champ }.from('cnaf').to('text')
      end

      it "converts the champ to text, keeping the identifiers as value and the fetched data" do
        process

        converted = Champs::TextChamp.find(champ.id)
        expect(converted.value).to eq('Numero allocataire : 1234567, Code postal : 75001')
        expect(converted.data).to eq(cnaf_data)
        expect(converted.external_id).to be_nil
        expect(converted.external_state).to eq('idle')
      end

      it "reads identifiers stored in value_json by the oldest rows" do
        champ.update_columns(external_id: nil, value_json: { 'numero_allocataire' => '7654321', 'code_postal' => '13001' })

        process

        expect(Champs::TextChamp.find(champ.id).value).to eq('Code postal : 13001, Numero allocataire : 7654321')
      end

      it "leaves value nil when nothing was filled" do
        champ.update_columns(external_id: nil, external_state: nil, data: nil)

        process

        expect(Champs::TextChamp.find(champ.id).value).to be_nil
      end
    end
  end
end
