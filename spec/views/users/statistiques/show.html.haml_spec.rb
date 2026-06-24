# frozen_string_literal: true

describe 'users/statistiques/show', type: :view do
  let(:procedure) { create(:procedure) }

  before do
    assign(:procedure, procedure)
  end

  subject { render }

  it "display stats" do
    expect(subject).to have_text("Répartition par semaine")
    expect(subject).to have_text("Avancée des dossiers")
    expect(subject).to have_text("Taux d’acceptation")
    expect(subject).to have_text(procedure.libelle)
  end

  it 'does not show the user indication mention' do
    expect(subject).not_to have_text("indiqué aux usagers")
  end
end
