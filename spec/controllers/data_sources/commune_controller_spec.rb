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

      context "when the API answers an error" do
        let(:upstream_response) do
          Typhoeus::Response.new(code: 504, body: "<!DOCTYPE html><html><body>#{'x' * 300}</body></html>", mock: true)
        end

        it "reports the failure with a truncated body and answers 502" do
          expect(Sentry).to receive(:capture_message).with("Commune API failure", extra: { code: 504, message: "HTTP 504", body: a_string_starting_with("<!DOCTYPE html>").and(having_attributes(length: 200)) })
          search
          expect(response).to have_http_status(:bad_gateway)
        end
      end

      context "when a successful answer is not JSON" do
        let(:upstream_response) do
          Typhoeus::Response.new(code: 200, body: "<!DOCTYPE html>", mock: true)
        end

        it "reports the failure and answers 502" do
          expect(Sentry).to receive(:capture_message).with("Commune API failure", extra: { code: 200, body: "<!DOCTYPE html>" })
          search
          expect(response).to have_http_status(:bad_gateway)
        end
      end
    end
  end
end
