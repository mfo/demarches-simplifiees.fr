# frozen_string_literal: true

describe 'As an administrateur I can browse all procedures', js: true do
  let(:administrateur) { administrateurs.blank }
  let(:zone) { Zone.find_by!(acronym: 'MEF') }

  before do
    create(:procedure, :published,
      zones: [zone],
      administrateurs: [administrateur],
      libelle: "DDAS9_JOURNEE_A_LA_MINE_ET_GRANDE_SORTIE_ANNUELLE_DU_PERSONNEL")
    login_as administrateur.user, scope: :user
  end

  scenario 'the table keeps every column visible with a zone filter and a long unbreakable libelle' do
    page.current_window.resize_to(1080, 900)
    visit all_admin_procedures_path(zone_ids: [zone.id])

    expect(page).to have_link('Cloner')

    table_right_edge, viewport_width = page.evaluate_script(
      "[document.querySelector('.fr-table__wrapper').getBoundingClientRect().right, document.documentElement.clientWidth]"
    )
    expect(table_right_edge).to be <= viewport_width
  end
end
