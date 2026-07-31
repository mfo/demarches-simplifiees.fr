# frozen_string_literal: true

describe "ActiveStorage representations", type: :request do
  # Direct upload is the one path that persists the content type declared by the
  # client without ever reading the file, so `identified` stays false. These bytes
  # are not a PNG: the image library picks its decoder from the leading bytes, not
  # from the content_type column.
  let(:bytes) { "MATLAB 5.0 MAT-file#{' ' * 512}" }

  let(:blob) do
    ActiveStorage::Blob.create_before_direct_upload!(
      filename: "image.png",
      byte_size: bytes.bytesize,
      checksum: Digest::MD5.base64digest(bytes),
      content_type: "image/png"
    ).tap { it.service.upload(it.key, StringIO.new(bytes)) }
  end

  let(:variation_key) { ActiveStorage::Variation.encode(resize_to_limit: [100, 100]) }

  subject(:representation_request) do
    get rails_blob_representation_path(
      signed_blob_id: blob.signed_id,
      variation_key:,
      filename: blob.filename
    )
  end

  describe "a blob whose declared content type was never checked against its bytes" do
    it "is not variable" do
      expect(blob).not_to be_variable
    end

    it "does not build a variant" do
      expect { representation_request }.not_to change { ActiveStorage::VariantRecord.count }
    end

    it "responds with not found" do
      representation_request

      expect(response).to have_http_status(:not_found)
    end
  end

  # The previewers are selected from the declared content type as well, and they
  # hand the bytes to pdftoppm and ffmpeg rather than to the image library.
  ["application/pdf", "video/mp4"].each do |declared_content_type|
    describe "a blob declared as #{declared_content_type} whose bytes were never checked" do
      let(:blob) do
        ActiveStorage::Blob.create_before_direct_upload!(
          filename: "file",
          byte_size: bytes.bytesize,
          checksum: Digest::MD5.base64digest(bytes),
          content_type: declared_content_type
        ).tap { it.service.upload(it.key, StringIO.new(bytes)) }
      end

      it "is not previewable" do
        expect(blob).not_to be_previewable
      end

      it "responds with not found" do
        representation_request

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "a blob whose content type was identified from its bytes" do
    let(:bytes) { Rails.root.join("spec/fixtures/files/logo_test_procedure.png").read }

    before { blob.identify }

    it "is variable" do
      expect(blob).to be_variable
    end
  end
end
