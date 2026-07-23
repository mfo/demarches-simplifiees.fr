# frozen_string_literal: true

RSpec.describe Users::DossierCardChampsComponent, type: :component do
  let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :text, libelle: 'Titre' }]) }
  let(:dossier) { create(:dossier, :en_construction, procedure:, populate_champs: true) }
  let(:column) { procedure.personnalisable_columns.first }

  it 'renders the formatted value with an info icon when the champ has a value' do
    champ = dossier.champs.find { _1.stable_id == column.stable_id }
    champ.update(value: 'Presse Océan')

    render_inline(described_class.new(columns: [column], champs_by_stable_id: { column.stable_id => champ.reload }))

    expect(page).to have_css('.fr-icon-info-i')
    expect(page).to have_text('Presse Océan')
  end

  it 'renders the formatted value for a brouillon dossier' do
    brouillon = create(:dossier, :brouillon, procedure:, populate_champs: true)
    champ = brouillon.champs.find { _1.stable_id == column.stable_id }
    champ.update(value: 'Valeur brouillon')

    render_inline(described_class.new(columns: [column], champs_by_stable_id: { column.stable_id => champ.reload }))

    expect(page).to have_css('.fr-icon-info-i')
    expect(page).to have_text('Valeur brouillon')
  end

  it 'renders nothing when the champ is missing or empty' do
    render_inline(described_class.new(columns: [column], champs_by_stable_id: {}))

    expect(page).not_to have_css('.fr-icon-info-i')
  end
end
