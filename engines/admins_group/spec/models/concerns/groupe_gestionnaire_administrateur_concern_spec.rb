# frozen_string_literal: true

describe GroupeGestionnaireAdministrateurConcern do
  it 'defines associations' do
    expect(Administrateur.new).to have_many(:commentaire_groupe_gestionnaires)
    expect(Administrateur.new).to belong_to(:groupe_gestionnaire).optional
  end

  describe "#unread_commentaires?" do
    context "commentaire_seen_at is nil" do
      let(:gestionnaire) { create(:gestionnaire) }
      let(:administrateur) { administrateurs.default }
      let(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }
      let!(:commentaire_groupe_gestionnaire) { create(:commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire, sender: administrateur, gestionnaire: gestionnaire, created_at: 12.hours.ago) }

      it do
        expect(administrateur.unread_commentaires?).to eq true
      end
    end

    context "commentaire_seen_at before last commentaire" do
      let(:gestionnaire) { create(:gestionnaire) }
      let(:administrateur) { create(:administrateur, commentaire_seen_at: 1.day.ago) }
      let(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }
      let!(:commentaire_groupe_gestionnaire) { create(:commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire, sender: administrateur, gestionnaire: gestionnaire, created_at: 12.hours.ago) }

      it do
        expect(administrateur.unread_commentaires?).to eq true
      end
    end

    context "commentaire_seen_at after last commentaire" do
      let(:gestionnaire) { create(:gestionnaire) }
      let(:administrateur) { create(:administrateur, commentaire_seen_at: 1.hour.ago) }
      let(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }
      let!(:commentaire_groupe_gestionnaire) { create(:commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire, sender: administrateur, gestionnaire: gestionnaire, created_at: 12.hours.ago) }

      it do
        expect(administrateur.unread_commentaires?).to eq false
      end
    end
  end

  describe "#mark_commentaire_as_seen" do
    let(:now) { Time.zone.now.beginning_of_minute }
    let(:gestionnaire) { create(:gestionnaire) }
    let(:administrateur) { administrateurs.default }
    let(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire]) }
    let!(:commentaire_groupe_gestionnaire) { create(:commentaire_groupe_gestionnaire, groupe_gestionnaire: groupe_gestionnaire, sender: administrateur, created_at: 12.hours.ago) }

    before do
      travel_to(now) do
        administrateur.mark_commentaire_as_seen
      end
    end

    it { expect(administrateur.commentaire_seen_at).to eq now }
  end
end
