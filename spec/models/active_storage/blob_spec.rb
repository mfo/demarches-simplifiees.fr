describe ActiveStorage::Blob, type: :model do
  describe 'create_before_direct_upload' do
    subject do
      ActiveStorage::Blob.create_before_direct_upload!(filename: 'test.png',
                                                       byte_size: 1010,
                                                       checksum: '12123',
                                                       content_type: 'text/plain')
    end

    context 'OBJECT_STORAGE_BLOB_PREFIXED_KEY=something' do
      before { allow(ENV).to receive(:[]).with('OBJECT_STORAGE_BLOB_PREFIXED_KEY').and_return('enabled') }

      it 'creates a direct upload with segments' do
        expect(subject.key.split('/').size).to eq(3)
      end

      it 'contains current year' do
        expect(subject.key.split('/')).to include(Time.now.strftime('%Y'))
      end

      it 'creates is marked as prefixed_key' do
        expect(subject.prefixed_key).to eq(true)
      end
    end

    context 'OBJECT_STORAGE_BLOB_PREFIXED_KEY inexistant' do
      before { allow(ENV).to receive('OBJECT_STORAGE_BLOB_PREFIXED_KEY').and_return(nil) }

      it 'creates a direct upload without segments' do
        expect(subject.key.split('/').size).to eq(1)
      end

      it 'creates a not prefixed_key' do
        expect(subject.prefixed_key).to eq(nil)
      end
    end
  end

  describe 'migrate_to_prefixed_key' do
    let(:champ_pj) { create(:champ_piece_justificative) }
    let(:pj) { champ_pj.piece_justificative_file[0].blob }
    let(:container) { 'dsbackup' }
    let(:client) { double(copy_object: true) }
    let(:service) { instance_double(ActiveStorage::Service::OpenStackService, upload: true, client: client, container: container) }
    before do
      require 'fog/openstack'
      require "active_storage/service/open_stack_service"

      allow_any_instance_of(ActiveStorage::Blob).to receive(:service).and_return(service)
    end

    context 'pj migrated' do
      before { pj.update(prefixed_key: true) }

      it { expect { subject }.not_to change { pj.reload.key } }
      it { expect { subject }.not_to change { pj.reload.prefixed_key } }
    end

    context 'pj not yet migrated' do
      subject { pj.migrate_to_prefixed_key }

      it { expect { subject }.to change { pj.reload.key } }
      it { expect { subject }.to change { pj.reload.prefixed_key }.from(nil).to(true) }

      it 'can retrieve former key' do
        former_key = pj.key.dup
        expect(pj.prefixed_key).to eq(nil)
        subject
        byebug
        pj.reload
        expect(pj.prefixed_key).to eq(true)
        expect(pj.former_key).to eq(former_key)
      end
    end
  end
end
