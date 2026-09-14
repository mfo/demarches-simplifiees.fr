# frozen_string_literal: true

describe DataSources::AdresseController, type: :controller do
  describe "#search" do
    let(:upstream_response) do
      Typhoeus::Response.new(code: 200, body: { features: [] }.to_json, mock: true)
    end

    before { allow(Typhoeus).to receive(:get).and_return(upstream_response) }

    subject(:search) { get :search, params: { q: "12 rue de la Paix" } }

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

      it "confines the user input to the query string of the configured address API host" do
        search
        expect(Typhoeus).to have_received(:get)
          .with(start_with(API_ADRESSE_URL), hash_including(params: hash_including(q: "12 rue de la Paix")))
      end

      context "when the API answers an error with a JSON body" do
        let(:upstream_response) do
          Typhoeus::Response.new(code: 503, body: { message: "Service indisponible" }.to_json, mock: true)
        end

        it "reports the failure with the upstream message and answers 502" do
          expect(Sentry).to receive(:capture_message).with("Adresse API failure", extra: { code: 503, message: "Service indisponible" })
          search
          expect(response).to have_http_status(:bad_gateway)
        end
      end

      context "when the API answers an error with an HTML page" do
        let(:upstream_response) do
          Typhoeus::Response.new(code: 504, body: "<!DOCTYPE html><html><body>#{'x' * 300}</body></html>", mock: true)
        end

        it "reports the failure with a truncated body and answers 502" do
          expect(Sentry).to receive(:capture_message).with("Adresse API failure", extra: { code: 504, body: a_string_starting_with("<!DOCTYPE html>").and(having_attributes(length: 200)) })
          search
          expect(response).to have_http_status(:bad_gateway)
        end
      end

      context "when a successful answer is not JSON" do
        let(:upstream_response) do
          Typhoeus::Response.new(code: 200, body: "<!DOCTYPE html>", mock: true)
        end

        it "reports the failure and answers 502" do
          expect(Sentry).to receive(:capture_message).with("Adresse API failure", extra: { code: 200, body: "<!DOCTYPE html>" })
          search
          expect(response).to have_http_status(:bad_gateway)
        end
      end
    end
  end

  describe "#clean_query" do
    subject(:clean_query) { controller.send(:clean_query, input) }

    context "when the query is valid but needs formatting" do
      let(:input) { "   123    rue  de   Paris   " }

      it "strips, collapses spaces, and returns the sanitized query" do
        expect(clean_query).to eq("123 rue de Paris")
      end
    end

    context "when the query starts with non alphanumeric characters" do
      let(:input) { "###Rue de la Paix" }

      it "removes the leading characters before returning" do
        expect(clean_query).to eq("Rue de la Paix")
      end
    end

    context "when the sanitized query is shorter than 3 characters" do
      let(:input) { "  a " }

      it { is_expected.to be_nil }
    end

    context "when the sanitized query exceeds 200 characters" do
      let(:input) { "a" * 201 }

      it "returns the first 200 characters" do
        expect(clean_query).to eq("a" * 200)
      end
    end
  end
end
