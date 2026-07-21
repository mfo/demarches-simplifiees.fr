# frozen_string_literal: true

describe 'experts/avis/instruction', type: :view do
  before do
    assign(:avis, current_avis)
    assign(:new_avis, Avis.new)
    assign(:dossier, current_avis.dossier)
    allow(view).to receive(:current_expert).and_return(current_avis.expert)
  end

  subject { render }

  context 'with a confidential avis' do
    let(:current_avis) { avis.confidentiel }
    it { is_expected.to have_text("Cet avis est confidentiel et n’est pas affiché aux autres experts consultés") }
  end

  context 'with a not confidential avis' do
    let(:current_avis) { avis.pending }
    it { is_expected.to have_text("Cet avis est partagé avec les autres experts") }
  end

  context 'when the avis has a question' do
    let(:current_avis) { create(:avis, question_label: "is it useful?", claimant: instructeurs.default, experts_procedure: experts_procedures.default, dossier: dossiers.en_instruction) }

    it do
      is_expected.to have_text(current_avis.question_label)
      is_expected.to have_unchecked_field("oui")
    end
  end

  context 'when the avis has no question' do
    let(:current_avis) { create(:avis, question_label: "", claimant: instructeurs.default, experts_procedure: experts_procedures.default, dossier: dossiers.en_instruction) }
    it { is_expected.not_to have_unchecked_field("oui") }
  end
end
