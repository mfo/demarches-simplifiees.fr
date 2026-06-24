# frozen_string_literal: true

describe "ActiveStorage configuration" do
  describe "blob analysis" do
    let(:blob) do
      image_path = Rails.root.join("spec/fixtures/files/logo_test_procedure.png")
      ActiveStorage::Blob.create_and_upload!(
        io: File.open(image_path),
        filename: "test.png",
        content_type: "image/png"
      )
    end

    it "does not enqueue AnalyzeJob when an image blob is created" do
      expect {
        ActiveStorage::Attachment.create!(
          name: "test",
          record: create(:dossier),
          blob: blob
        )
      }.not_to have_enqueued_job(ActiveStorage::AnalyzeJob)
    end

    it "pre-marks blobs as analyzed and does not UPDATE active_storage_blobs when an attachment is created" do
      # The blob must be pre-marked as analyzed at INSERT time so that
      # `Attachment#analyze_blob_later` (after_create_commit) short-circuits
      # via its `unless blob.analyzed?` guard. Otherwise, with `analyzers = []`,
      # ActiveStorage falls back to NullAnalyzer whose `analyze_later? == false`,
      # and `analyze` runs inline, issuing an unnecessary UPDATE on
      # `active_storage_blobs`. Under contention (e.g., a batch op with N
      # workers attaching the same blob), this UPDATE serializes on the same
      # row and hits PG statement_timeout in production.
      blob_updates = []
      callback = -> (_, _, _, _, payload) {
        sql = payload[:sql]
        blob_updates << sql if sql.match?(/UPDATE\s+"active_storage_blobs"/i)
      }

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        ActiveStorage::Attachment.create!(
          name: "test",
          record: create(:dossier),
          blob: blob
        )
      end

      expect(blob.analyzed?).to be(true)
      expect(blob_updates).to be_empty
    end
  end

  describe "JPEG filename normalization on upload" do
    let(:image_path) { Rails.root.join("spec/fixtures/files/image-no-rotation.jpg") }

    def create_blob(filename:, content_type: "image/jpeg")
      ActiveStorage::Blob.create_and_upload!(
        io: File.open(image_path),
        filename:,
        content_type:
      )
    end

    %w[jfif jfi jif jpe].each do |ext|
      it "rewrites a .#{ext} JPEG filename to .jpg at upload" do
        expect(create_blob(filename: "photo.#{ext}").filename.to_s).to eq("photo.jpg")
      end
    end

    it "is case-insensitive on the extension" do
      expect(create_blob(filename: "photo.JFIF").filename.to_s).to eq("photo.jpg")
    end

    it "leaves a standard .jpg filename untouched" do
      expect(create_blob(filename: "photo.jpg").filename.to_s).to eq("photo.jpg")
    end

    it "does not rewrite when the content-type is not image/jpeg" do
      pdf_blob = ActiveStorage::Blob.create_and_upload!(
        io: Rails.root.join("spec/fixtures/files/dossierPDF.pdf").open,
        filename: "weird.jfif",
        content_type: "application/pdf"
      )
      expect(pdf_blob.filename.to_s).to eq("weird.jfif")
    end
  end

  describe "per-procedure storage service for direct upload" do
    let(:procedure) { create(:procedure) }

    def create_direct_upload_blob(procedure_id:)
      ActiveStorage::Blob.create_before_direct_upload!(
        filename: "doc.pdf",
        byte_size: 3,
        checksum: Digest::MD5.base64digest("doc"),
        content_type: "application/pdf",
        procedure_id:
      )
    end

    context "when the s3_storage feature is enabled on the procedure" do
      before { Flipper.enable(:s3_storage, procedure) }

      it "creates the blob on the amazon service" do
        expect(create_direct_upload_blob(procedure_id: procedure.id).service_name).to eq("amazon")
      end
    end

    context "when the s3_storage feature is disabled" do
      it "creates the blob on the default service" do
        expect(create_direct_upload_blob(procedure_id: procedure.id).service_name).to eq("test")
      end
    end

    context "without a procedure_id" do
      it "creates the blob on the default service" do
        expect(create_direct_upload_blob(procedure_id: nil).service_name).to eq("test")
      end
    end
  end
end
