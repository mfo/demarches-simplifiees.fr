# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260504BackfillCanonicalKeysInDepartementChampsTask do
    let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :departements }]) }
    let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
    let(:champ) { dossier.champ_data.first }

    describe "#process" do
      let(:range) { (champ.id)...(champ.id + 1) }

      subject(:process) { described_class.new.process(range) }

      context "when only legacy keys are present" do
        before do
          champ.update_columns(
            value: "Paris",
            external_id: "75",
            value_json: { 'code_region' => '11' }
          )
        end

        it "adds canonical keys without removing legacy ones" do
          process
          expect(champ.reload.value_json).to eq({
            'code_region' => '11',
            'department_code' => '75',
            'region_code' => '11',
          })
        end
      end

      context "when value_json is nil" do
        before do
          champ.update_columns(value: "Paris", external_id: "75", value_json: nil)
        end

        it "creates value_json with department_code from external_id" do
          process
          expect(champ.reload.value_json).to eq({
            'department_code' => '75',
          })
        end
      end

      context "when external_id and legacy keys are all nil" do
        before do
          champ.update_columns(value: nil, external_id: nil, value_json: {})
        end

        it "leaves value_json empty" do
          process
          expect(champ.reload.value_json).to eq({})
        end
      end

      context "when canonical keys already hold stale values" do
        before do
          champ.update_columns(
            value: "Paris",
            external_id: "75",
            value_json: {
              'code_region' => '11',
              'department_code' => 'OBSOLETE',
              'region_code' => 'OBSOLETE',
            }
          )
        end

        it "overwrites canonical keys with values from columns and legacy keys" do
          process
          expect(champ.reload.value_json).to eq({
            'code_region' => '11',
            'department_code' => '75',
            'region_code' => '11',
          })
        end
      end

      context "when champ id is outside the processed range" do
        let(:range) { (champ.id + 1)...(champ.id + 100) }

        before do
          champ.update_columns(
            value: "Paris",
            external_id: "75",
            value_json: { 'code_region' => '11' }
          )
        end

        it "does not modify the champ" do
          expect { process }.not_to(change { champ.reload.value_json })
        end
      end

      context "when running twice on the same champ" do
        before do
          champ.update_columns(
            value: "Paris",
            external_id: "75",
            value_json: { 'code_region' => '11' }
          )
        end

        it "is idempotent" do
          process
          first_pass = champ.reload.value_json
          process
          expect(champ.reload.value_json).to eq(first_pass)
        end
      end
    end

    describe "#collection" do
      before { champ }

      it "returns ranges that cover existing champ ids" do
        collection = described_class.new.collection
        expect(collection.any? { |range| range.include?(champ.id) }).to be(true)
      end
    end

    describe "#count" do
      before { champ }

      it "returns the number of ranges" do
        expect(described_class.new.count).to eq(1)
      end
    end
  end
end
