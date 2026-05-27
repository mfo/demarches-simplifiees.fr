# frozen_string_literal: true

describe DataSources::CommuneController, type: :controller do
  describe "#search" do
    let(:upstream_response) do
      Typhoeus::Response.new(code: 200, body: [].to_json, mock: true)
    end

    before { allow(APIGeoService).to receive(:commune_by_name_or_postal_code).and_return(upstream_response) }

    subject(:search) { get :search, params: { q: "Lyon" } }

    context "without a signed-in user" do
      it "redirects to the sign-in page instead of proxying the request" do
        search
        expect(response).to redirect_to(new_user_session_path)
        expect(APIGeoService).not_to have_received(:commune_by_name_or_postal_code)
      end
    end

    context "with a signed-in user" do
      before { sign_in(create(:user)) }

      it "answers with the formatted results" do
        search
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
