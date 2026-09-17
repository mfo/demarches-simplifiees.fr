# frozen_string_literal: true

describe Administrateurs::GroupeGestionnaireController, type: :controller do
  let(:admin) { administrateurs.default }

  describe "#show" do
    render_views

    subject { get :show }

    context "when not logged" do
      before { subject }
      it { expect(response).to redirect_to(new_user_session_path) }
    end

    context "when logged in" do
      let(:gestionnaire) { create(:gestionnaire) }
      let!(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire], administrateurs: [admin]) }
      before do
        sign_in(admin.user)
        subject
      end

      it do
        expect(response).to have_http_status(:ok)
        expect(assigns(:groupe_gestionnaire)).to eq(groupe_gestionnaire)
        expect(response.body).to match(%r{<div class="metadatas[^"]*">\s*<h1[^>]*>#{Regexp.escape(groupe_gestionnaire.name)}</h1>})
      end

      # Contributed to the administrateur nav bar through ViewExtensionHelper.
      # Matched on the nav link itself: the breadcrumb of this very page carries
      # the same label, so a bare include() would pass without the contribution.
      it 'shows the nav bar link to the group' do
        expect(response.body).to match(%r{<a[^>]*class="fr-nav__link"[^>]*>Mon groupe gestionnaire</a>})
      end
    end
  end

  describe "#gestionnaires" do
    subject { get :gestionnaires }
    let(:gestionnaire) { create(:gestionnaire) }
    let!(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire], administrateurs: [admin]) }

    context "when not logged" do
      before { subject }
      it { expect(response).to redirect_to(new_user_session_path) }
    end

    context "when logged in" do
      before do
        sign_in(admin.user)
        subject
      end

      it do
        expect(response).to have_http_status(:ok)
        expect(assigns(:groupe_gestionnaire)).to eq(groupe_gestionnaire)
      end
    end
  end

  describe "#administrateurs" do
    subject { get :administrateurs }
    let(:gestionnaire) { create(:gestionnaire) }
    let!(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire], administrateurs: [admin]) }

    context "when not logged" do
      before { subject }
      it { expect(response).to redirect_to(new_user_session_path) }
    end

    context "when logged in" do
      before do
        sign_in(admin.user)
        subject
      end

      it do
        expect(response).to have_http_status(:ok)
        expect(assigns(:groupe_gestionnaire)).to eq(groupe_gestionnaire)
      end
    end
  end

  describe '#commentaires' do
    let(:gestionnaire) { create(:gestionnaire) }
    let!(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire], administrateurs: [admin]) }
    subject { get :commentaires }

    context "when not logged" do
      before { subject }
      it { expect(response).to redirect_to(new_user_session_path) }
    end

    context "when logged in" do
      before do
        sign_in(admin.user)
      end

      it { expect(subject).to have_http_status(:ok) }
    end
  end

  describe "#create_commentaire" do
    let(:gestionnaire) { create(:gestionnaire) }
    let!(:groupe_gestionnaire) { create(:groupe_gestionnaire, gestionnaires: [gestionnaire], administrateurs: [admin]) }
    let(:body) { "avant\napres" }

    subject {
      post :create_commentaire, params: {
        commentaire_groupe_gestionnaire: {
          body: body,
        },
      }
    }

    context "when not logged" do
      before { subject }
      it { expect(response).to redirect_to(new_user_session_path) }
    end

    context "when logged in" do
      let(:gestionnaire_2) { create(:gestionnaire) }

      before do
        groupe_gestionnaire.gestionnaires << gestionnaire_2
        sign_in(admin.user)
      end

      it "creates a commentaire" do
        expect { subject }.to change(CommentaireGroupeGestionnaire, :count).by(1)

        expect(response).to redirect_to(admin_groupe_gestionnaire_commentaires_path)
        expect(flash.notice).to be_present
      end

      it '2 emails are sent' do
        expect { perform_enqueued_jobs { subject } }.to change { ActionMailer::Base.deliveries.count }.by(2)
      end
    end
  end
end
