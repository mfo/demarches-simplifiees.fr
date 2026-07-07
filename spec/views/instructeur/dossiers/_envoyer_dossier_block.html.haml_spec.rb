# frozen_string_literal: true

describe Instructeurs::EnvoyerDossierFormComponent, type: :component do
  let(:dossier) { create(:dossier) }

  subject do
    render_inline(described_class.new(dossier:, potential_recipients:))
  end

  context "there are other instructeurs for the procedure" do
    let(:instructeur) { create(:instructeur, email: 'yop@totomail.fr') }
    let(:potential_recipients) { [instructeur] }

    it do
      expect(subject.to_html).to include(instructeur.email)
      expect(page).to have_css(".fr-btn")
      expect(page).to have_css("label.fr-label[for='envoyer-dossier-select']")
    end
  end

  context "there is no other instructeur for the procedure" do
    let(:potential_recipients) { [] }

    it do
      subject
      expect(page).not_to have_css("select")
      expect(page).not_to have_css(".fr-btn")
      expect(page).to have_text("Vous êtes le seul instructeur assigné sur cette démarche")
    end
  end
end
