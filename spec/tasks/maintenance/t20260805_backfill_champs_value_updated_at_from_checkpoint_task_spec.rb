# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20260805BackfillChampsValueUpdatedAtFromCheckpointTask do
    let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :text }]) }
    let(:dossier) { create(:dossier, :en_construction, :with_populated_champs, procedure:) }
    let(:champ) { dossier.champ_data.first }

    describe "#process" do
      subject(:process) { described_class.process(ChampData.where(id: champ.id)) }

      it "copies the merge time embedded in the checkpoint without touching updated_at" do
        champ.update_columns(checkpoint: "history:2026-07-01 10:00:00 +0200", value_updated_at: nil)

        expect { process }.not_to change { champ.reload.updated_at }
        expect(champ.reload.read_attribute(:value_updated_at)).to eq(Time.zone.parse("2026-07-01 10:00:00 +0200"))
      end

      it "skips champs without checkpoint" do
        champ.update_columns(checkpoint: nil, value_updated_at: nil)

        expect { process }.not_to change { champ.reload.read_attribute(:value_updated_at) }.from(nil)
      end

      it "skips champs already stamped" do
        already = 1.week.ago.change(usec: 0)
        champ.update_columns(checkpoint: "history:2026-07-01 10:00:00 +0200", value_updated_at: already)

        expect { process }.not_to change { champ.reload.read_attribute(:value_updated_at) }.from(already)
      end

      it "skips champs outside the main stream" do
        champ.update_columns(checkpoint: "history:2026-07-01 10:00:00 +0200", value_updated_at: nil, stream: "history:2026-07-02 10:00:00 +0200")

        expect { process }.not_to change { champ.reload.read_attribute(:value_updated_at) }.from(nil)
      end

      it "stamps the same instant the merge wrote to updated_at" do
        dossier.with_update_stream(dossier.user) do
          dossier.public_champ_for_update(champ.stable_id.to_s, updated_by: dossier.user.email).assign_attributes(value: "Nouvelle valeur")
        end
        dossier.save!
        dossier.merge_user_buffer_stream!

        merged = dossier.champ_data.find { _1.stable_id == champ.stable_id && _1.main_stream? }.reload
        merged.update_column(:value_updated_at, nil) # simulate a pre-column legacy row

        described_class.process(ChampData.where(id: merged.id))

        expect(merged.reload.read_attribute(:value_updated_at)).to be_within(1.second).of(merged.updated_at)
      end
    end

    describe "#collection" do
      it "enumerates primary-key batches without filtering (filters live in each batch's UPDATE)" do
        expect(described_class.new.collection).to be_a(ActiveRecord::Batches::BatchEnumerator)
      end
    end
  end
end
