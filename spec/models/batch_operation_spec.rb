describe BatchOperation, type: :model do
  describe 'association' do
    it { is_expected.to have_many(:dossiers) }
    it { is_expected.to belong_to(:instructeur) }
    it { is_expected.to have_one_attached(:justificatif_motivation) }
  end

  describe 'attributes' do
    subject { BatchOperation.new }
    it { expect(subject.payload).to eq({}) }
    it { expect(subject.failed_dossier_ids).to eq([]) }
    it { expect(subject.success_dossier_ids).to eq([]) }
    it { expect(subject.run_at).to eq(nil) }
    it { expect(subject.finished_at).to eq(nil) }
    it { expect(subject.operation).to eq(nil) }
    it { expect(subject.justificatif_motivation).to be_an_instance_of(ActiveStorage::Attached::One) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:operation) }
  end

  describe 'enqueue_all' do
    context 'given dossier_ids not in instructeur procedures' do
      subject do
        create(:batch_operation, :archiver, instructeur: create(:instructeur), invalid_instructeur: create(:instructeur))
      end

      it 'does not enqueues any BatchOperationProcessOneJob' do
        expect { subject.enqueue_all() }
          .not_to have_enqueued_job(BatchOperationProcessOneJob)
      end
    end

    context 'given dossier_ids in instructeur procedures' do
      subject do
        create(:batch_operation, :archiver, instructeur: create(:instructeur))
      end

      it 'enqueues as many BatchOperationProcessOneJob as dossiers_ids' do
        expect { subject.enqueue_all() }
          .to have_enqueued_job(BatchOperationProcessOneJob)
          .with(subject, subject.dossiers.first)
          .with(subject, subject.dossiers.second)
          .with(subject, subject.dossiers.third)
      end
    end
  end

  describe 'process_one' do
    let(:dossier) { batch_operation.dossiers.first }

    context 'archiver' do
      let(:batch_operation) { create(:batch_operation, :archiver, instructeur: create(:instructeur)) }
      it 'archives stuff' do
        expect { batch_operation.process_one(dossier) }
          .to change { dossier.reload.archived }.from(false).to(true)
      end
    end

    context 'accepter' do
      let(:batch_operation) { create(:batch_operation, :accepter, instructeur: create(:instructeur)) }

      it 'accepter stuff' do
        expect { batch_operation.process_one(dossier) }
          .to change { dossier.reload.state }.from('en_instruction').to('accepte')
      end
    end
  end
end
