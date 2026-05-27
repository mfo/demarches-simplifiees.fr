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
