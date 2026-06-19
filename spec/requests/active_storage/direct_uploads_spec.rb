# frozen_string_literal: true

describe "ActiveStorage direct uploads", type: :request do
  let(:procedure) { create(:procedure) }
  let(:blob_params) do
    {
      blob: {
        filename: "doc.pdf",
        byte_size: 3,
        checksum: Digest::MD5.base64digest("doc"),
        content_type: "application/pdf",
      },
    }
  end

  subject(:created_blob) do
    post(url, params: blob_params, as: :json)
    ActiveStorage::Blob.find(response.parsed_body["id"])
  end

  context "with a procedure_id whose s3_storage feature is enabled" do
    let(:url) { rails_direct_uploads_path(procedure_id: procedure.id) }

    before { Flipper.enable(:s3_storage, procedure) }

    it "creates the blob on the amazon service" do
      expect(created_blob.service_name).to eq("amazon")
    end
  end

  context "without procedure scoping" do
    let(:url) { rails_direct_uploads_path }

    it "creates the blob on the default service" do
      expect(created_blob.service_name).to eq("test")
    end
  end
end
