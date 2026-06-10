# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe RegenerateAttestationTask do
    describe "#collection" do
      let!(:dossier1) { create(:dossier) }
      let!(:dossier2) { create(:dossier) }

      it "targets the dossiers matching the comma/space separated ids" do
        task = described_class.new
        task.dossier_ids = " #{dossier1.id}, #{dossier2.id} "
        expect(task.collection).to contain_exactly(dossier1, dossier2)
      end
    end

    describe "#process" do
      let(:dossier) { create(:dossier, :accepte) }
      let!(:broken_attestation) { create(:attestation, dossier:) }

      it "destroys the broken attestation and enqueues a regeneration job" do
        expect { described_class.new.process(dossier) }
          .to have_enqueued_job(AttestationPdfGenerationJob).with(dossier)
          .and change { Attestation.exists?(broken_attestation.id) }.from(true).to(false)
      end
    end
  end
end
