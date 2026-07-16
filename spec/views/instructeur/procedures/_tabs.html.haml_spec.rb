# frozen_string_literal: true

describe 'instructeurs/procedures/_tabs', type: :view do
  let(:procedure) { create(:procedure) }

  before { allow(view).to receive(:current_instructeur).and_return(create(:instructeur)) }

  subject do
    render('instructeurs/procedures/tabs',
            procedure: procedure,
            statut: 'tous',
            a_suivre_count: 0,
            suivis_count: 0,
            traites_count: 0,
            tous_count: 0,
            supprimes_count: 0,
            archives_count: 0,
            expirant_count: 0,
            statut_with_notifications: { suivis: false, traites: false })
  end

  it 'contains link to expiring dossiers within procedure' do
    expect(subject).to have_selector(%Q(a[href="#{instructeur_procedure_path(procedure, statut: 'expirant')}"]), count: 1)
  end
end
