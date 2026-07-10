# frozen_string_literal: true

RSpec.describe Instructeurs::EditDossierButtonComponent, type: :component do
  let(:procedure) { create(:procedure, :published, instructeurs: [instructeur], instructeurs_can_edit_dossiers:) }
  let(:instructeur) { create(:instructeur) }
  let(:dossier) { create(:dossier, :en_construction, procedure:) }
  let(:instructeurs_can_edit_dossiers) { true }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(instructeur.user)
  end

  subject do
    with_request_url "/procedures/#{procedure.id}/dossiers/#{dossier.id}" do
      render_inline(described_class.new(dossier:))
    end
  end

  context "when the procedure does not allow instructeurs to edit dossiers" do
    let(:instructeurs_can_edit_dossiers) { false }

    it "renders nothing" do
      expect(subject.to_html).to be_empty
    end
  end

  context "when the instructeur can edit the dossier" do
    it "renders the edit link" do
      expect(subject).to have_link("Modifier le dossier")
    end
  end

  context "when the dossier is en instruction" do
    let(:dossier) { create(:dossier, :en_instruction, procedure:) }

    it "renders a disabled button" do
      expect(subject).to have_button("Modifier le dossier", disabled: true)
    end
  end

  context "when the instructeur owns the dossier" do
    let(:dossier) { create(:dossier, :en_construction, procedure:, user: instructeur.user) }

    it "renders a disabled button" do
      expect(subject).to have_button("Modifier le dossier", disabled: true)
    end
  end
end
