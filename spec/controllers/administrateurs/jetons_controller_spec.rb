# frozen_string_literal: true

describe Administrateurs::JetonsController, type: :controller do
  let(:admin) { administrateurs(:default_admin) }
  let(:procedure) { create(:procedure, administrateur: admin) }

  context 'API Entreprise' do
    before do
      sign_in(admin.user)
    end
    describe 'GET #edit_entreprise' do
      let(:procedure) { create(:procedure, administrateur: admin) }

      subject { get :edit_entreprise, params: { procedure_id: procedure.id } }

      it { is_expected.to have_http_status(:success) }
    end

    describe 'PATCH #update_entreprise' do
      let(:procedure) { create(:procedure, administrateur: admin) }
      let(:token) { "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c" }
      let(:api_response_body) { nil }

      subject { patch :update_entreprise, params: { procedure_id: procedure.id, procedure: { api_entreprise_token: token } } }

      before do
        if api_response_body
          stub_request(:get, "https://entreprise.api.gouv.fr/privileges")
            .to_return(body: api_response_body, status: api_response_status)
        end
      end

      context 'when jeton is valid' do
        let(:api_response_status) { 200 }
        let(:api_response_body) { File.read('spec/fixtures/files/api_entreprise/privileges.json') }

        it do
          subject
          expect(flash.alert).to be_nil
          expect(flash.notice).to eq('Le jeton a bien été mis à jour')
          expect(procedure.reload.api_entreprise_token.jwt_token).to eq(token)
        end
      end

      context 'when jeton is invalid' do
        let(:api_response_status) { 403 }
        let(:api_response_body) { '' }

        it do
          subject
          expect(flash.alert).to eq("Mise à jour impossible : le jeton n’est pas valide")
          expect(flash.notice).to be_nil
          expect(procedure.reload.api_entreprise_token).not_to eq(token)
        end
      end

      context 'when jeton is not a jwt' do
        let(:token) { "invalid" }

        it do
          subject
          expect(flash.alert).to eq("Mise à jour impossible : le jeton n’est pas valide")
          expect(flash.notice).to be_nil
          expect(procedure.reload.api_entreprise_token).not_to eq(token)
        end
      end
    end

    describe 'DELETE #destroy_entreprise' do
      let(:procedure) { create(:procedure, administrateur: admin) }

      subject { delete :destroy_entreprise, params: { procedure_id: procedure.id } }

      it do
        subject
        expect(flash.notice).to eq("Le jeton API Entreprise a bien été supprimé")
        expect(procedure.reload.specific_api_entreprise_token?).to eq(false)
      end
    end
  end

  context 'API Particulier' do
    before do
      stub_const("API_PARTICULIER_URL", "https://particulier.api.gouv.fr")

      sign_in(admin.user)
    end

    describe "GET #edit_particulier" do
      render_views

      subject { get :edit_particulier, params: { procedure_id: procedure.id } }

      it do
        is_expected.to have_http_status(:success)
        expect(subject.body).to have_content('Jeton API particulier')
      end
    end

    describe "PATCH #update_particulier" do
      subject { patch :update_particulier, params: { procedure_id: procedure.id, procedure: { api_particulier_token: token } } }

      context "when jeton has a valid shape" do
        let(:token) { "d7e9c9f4c3ca00caadde31f50fd4521a" }

        it 'saves the jeton' do
          subject
          expect(flash.alert).to be_nil
          expect(flash.notice).to eq("Le jeton a bien été mis à jour")
        end
      end

      context "when jeton is invalid" do
        let(:token) { "jet0n 1nvalide" }

        it 'rejects the jeton' do
          subject
          expect(flash.alert).to eq("Mise à jour impossible : le jeton n’est pas valide")
          expect(flash.notice).to be_nil
          expect(procedure.reload.api_particulier_token).not_to eql(token)
        end
      end
    end

    describe 'DELETE #destroy_particulier' do
      let(:procedure) { create(:procedure, administrateur: admin, api_particulier_token:) }
      let(:api_particulier_token) { "d7e9c9f4c3ca00caadde31f50fd4521a" }

      subject { delete :destroy_particulier, params: { procedure_id: procedure.id } }

      it do
        subject
        expect(flash.notice).to eq("Le jeton API Particulier a bien été supprimé")
        expect(procedure.reload.api_particulier_token).to eq(nil)
      end
    end
  end
end
