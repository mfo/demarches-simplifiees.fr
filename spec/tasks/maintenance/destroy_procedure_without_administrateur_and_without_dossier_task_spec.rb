# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe DestroyProcedureWithoutAdministrateurAndWithoutDossierTask do
    describe "#process" do
      subject(:process) { described_class.process(procedure) }
      let(:administrateur) { administrateurs.blank }
      let!(:procedure) { create(:procedure, administrateurs: [administrateur]) }

      before do
        AdministrateursProcedure.where(administrateur_id: administrateur.id).delete_all
        administrateur.destroy
      end

      it "destroys procedure" do
        subject
        expect(Procedure.with_discarded.exists?(procedure.id)).to be(false)
      end
    end
  end
end
