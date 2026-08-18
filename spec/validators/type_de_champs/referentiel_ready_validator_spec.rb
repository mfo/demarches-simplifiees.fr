# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TypeDeChamps::ReferentielReadyValidator do
  let(:procedure) { create(:procedure, public_type_de_champs:) }
  let(:referentiel) { create(:api_referentiel, :exact_match) }
  let(:public_type_de_champs) { [{ type: :referentiel, referentiel: }] }

  subject { procedure.validate(:public_type_de_champs_editor) }

  context 'when all referentiel is ready' do
    before { expect_any_instance_of(Referentiels::APIReferentiel).to receive(:ready?).and_return(true) }

    it 'does not add errors to the procedure' do
      expect { subject }.not_to change { procedure.errors.count }
    end
  end

  context 'when all referentiel is not ready' do
    before { expect_any_instance_of(Referentiels::APIReferentiel).to receive(:ready?).and_return(false) }

    it 'does not add errors to the procedure' do
      expect { subject }.to change { procedure.errors.count }
    end
  end
end
