# frozen_string_literal: true

require 'rails_helper'

describe DelayedPurgeJob, type: :job do
  let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :piece_justificative }]) }
  let!(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
  let(:blob) { dossier.champ_data.first.piece_justificative_file.first.blob }
  let(:job) { described_class.new(blob) }
  let(:client) { double('OpenStack client') }
  let(:pool) { double('ConnectionPool') }

  before do
    stub_const('ENV', ENV.to_hash.merge('PURGE_LATER_DELAY_IN_DAY' => '1'))
  end

  let(:subject) { job.perform_now }

  context 'emit request instead of destroying it' do
    let(:container) { "bucket" }
    let(:client) { double("client") }
    let(:double_service) { double(name: :openstack, container:) }
    let(:cloned_dossier) { dossier.clone }

    before do
      allow_any_instance_of(ActiveStorage::Blob).to receive(:service).and_return(double_service)
      allow_any_instance_of(DelayedPurgeJob).to receive(:client).and_return(client)
    end

    it 'with attachments' do
      expect(client).not_to receive(:copy_object)
      subject
      perform_enqueued_jobs
    end

    it 'without attachments' do
      dossier.champ_data.first.piece_justificative_file.first.delete
      expect(client).to receive(:copy_object)
        .with(container, blob.key, container, blob.key, { 'X-Delete-At' => anything, "Content-Type" => blob.content_type })
        .and_return(double(status: 201))
      subject
      perform_enqueued_jobs
      expect(blob.reload.soft_deleted_at).to be_present
    end

    it 'does not mark soft_deleted_at when the copy fails' do
      dossier.champ_data.first.piece_justificative_file.first.delete
      expect(client).to receive(:copy_object).and_return(double(status: 500))
      expect(Sentry).to receive(:capture_message)
      subject
      perform_enqueued_jobs
      expect(blob.reload.soft_deleted_at).to be_nil
    end

    it 'with cloned dossier' do
      expect { cloned_dossier.destroy }.to have_enqueued_job(DelayedPurgeJob)
      perform_enqueued_jobs

      expect(client).to receive(:copy_object)
        .with(container, blob.key, container, blob.key, { 'X-Delete-At' => anything, "Content-Type" => blob.content_type })
        .and_return(double(status: 201))

      expect { dossier.destroy }.to have_enqueued_job(DelayedPurgeJob)
      perform_enqueued_jobs
    end
  end

  context 'when a soft-deleted image has variants' do
    let(:container) { "bucket" }
    let(:client) { double("client") }

    # Blobs are created against the real service, then the OpenStack service is
    # mocked; the parent copy_object is stubbed to succeed.
    def setup_image_with_variant
      image_blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("img"), filename: "i.png", content_type: "image/png")
      variant_blob = ActiveStorage::Blob.create_and_upload!(io: StringIO.new("variant"), filename: "v.png", content_type: "image/png")
      variant_record = ActiveStorage::VariantRecord.create!(blob: image_blob, variation_digest: "digest")
      image_attachment = ActiveStorage::Attachment.create!(name: "image", record: variant_record, blob: variant_blob)

      allow_any_instance_of(ActiveStorage::Blob).to receive(:service).and_return(double(name: :openstack, container:))
      job = described_class.new(image_blob)
      allow(job).to receive(:client).and_return(client)
      allow(client).to receive(:copy_object).and_return(double(status: 201))

      { job:, image_blob:, variant_blob:, variant_record:, image_attachment: }
    end

    it 'marks the variant files for expiration and keeps their rows for the cron' do
      ctx = setup_image_with_variant
      expect(client).to receive(:copy_object)
        .with(container, ctx[:variant_blob].key, container, ctx[:variant_blob].key, hash_including('X-Delete-At'))
        .and_return(double(status: 201))

      ctx[:job].perform_now

      expect(ActiveStorage::Blob.where(id: ctx[:variant_blob].id)).to exist
      expect(ActiveStorage::VariantRecord.where(id: ctx[:variant_record].id)).to exist
      expect(ActiveStorage::Attachment.where(id: ctx[:image_attachment].id)).to exist
      expect(ActiveStorage::Blob.where(id: ctx[:image_blob].id)).to exist # parent soft-deleted
    end

    it 'reports to Sentry when a variant copy fails, keeping the rows' do
      ctx = setup_image_with_variant
      allow(client).to receive(:copy_object)
        .with(container, ctx[:variant_blob].key, container, ctx[:variant_blob].key, anything)
        .and_return(double(status: 500))
      expect(Sentry).to receive(:capture_message).with("Can't expire blob", extra: hash_including(key: ctx[:variant_blob].key))

      ctx[:job].perform_now

      expect(ActiveStorage::VariantRecord.where(id: ctx[:variant_record].id)).to exist
      expect(ActiveStorage::Blob.where(id: ctx[:variant_blob].id)).to exist
    end
  end

  context 'when destroying an instance' do
    it 'uses our custom job' do
      expect { dossier.destroy }.to have_enqueued_job(DelayedPurgeJob)
      perform_enqueued_jobs
    end
  end

  context 'when the blob is stored on a non-OpenStack service (e.g. S3)' do
    let(:s3_service) { double(name: :amazon) }

    before do
      allow_any_instance_of(ActiveStorage::Blob).to receive(:service).and_return(s3_service)
    end

    it 'purges the blob directly instead of soft-deleting it' do
      expect(blob).to receive(:purge)
      subject
    end
  end

  context 'error handling' do
    context 'Excon::Error::RequestEntityTooLarge' do
      let(:error) { Excon::Error::RequestEntityTooLarge.new('Request Entity Too Large') }

      it 'handles the error by purging the blob' do
        allow_any_instance_of(ActiveStorage::Blob).to receive(:service).and_raise(error)
        expect(blob).to receive(:purge)

        # The job should rescue the error and purge the blob without raising
        expect { subject }.not_to raise_error
      end
    end
  end
end
