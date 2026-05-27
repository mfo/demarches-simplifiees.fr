# frozen_string_literal: true

describe DataSources::EducationController, type: :controller do
  describe "#search" do
    let(:upstream_response) do
      Typhoeus::Response.new(code: 200, body: { records: [] }.to_json, mock: true)
    end

    before { allow(Typhoeus).to receive(:get).and_return(upstream_response) }

    subject(:search) { get :search, params: { q: "lycee" } }

    context "without a signed-in user" do
      it "redirects to the sign-in page instead of proxying the request" do
        search
        expect(response).to redirect_to(new_user_session_path)
        expect(Typhoeus).not_to have_received(:get)
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
