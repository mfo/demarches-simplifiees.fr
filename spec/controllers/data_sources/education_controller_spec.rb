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

      context "when a successful answer is not JSON" do
        let(:upstream_response) do
          Typhoeus::Response.new(code: 200, body: "<!DOCTYPE html><html><body>#{'x' * 300}</body></html>", mock: true)
        end

        it "reports the failure with a truncated body and answers an empty list" do
          expect(Sentry).to receive(:capture_message).with("Education API failure", extra: { code: 200, body: a_string_starting_with("<!DOCTYPE html>").and(having_attributes(length: 200)) })
          expect(Sentry).not_to receive(:capture_exception)
          search
          expect(response).to have_http_status(:ok)
          expect(response.parsed_body).to eq([])
        end
      end
    end
  end
end
