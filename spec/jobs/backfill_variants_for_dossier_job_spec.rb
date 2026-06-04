# frozen_string_literal: true

RSpec.describe BackfillVariantsForDossierJob, type: :job do
  let(:procedure) { create(:procedure, types_de_champ_public: [{ type: :piece_justificative }]) }
  let(:dossier) { create(:dossier, :en_construction, procedure:) }

  describe '#perform' do
    context 'when dossier exists' do
      it 'does not raise an error' do
        expect { described_class.perform_now(dossier.id, '') }.not_to raise_error
      end
    end

    context 'when dossier does not exist' do
      it 'discards the job without error' do
        expect { described_class.perform_now(nil, '') }.not_to raise_error
      end
    end
  end

  describe '#skip_attachment?' do
    let(:job) { described_class.new }
    let(:champ) { dossier.champ_data.first }
    let(:attachment) { champ.piece_justificative_file.first }

    before do
      champ.piece_justificative_file.attach(
        io: StringIO.new('test'),
        filename: 'test.jpg',
        content_type: 'image/jpeg'
      )
    end

    it 'skips image when file_type is pdf' do
      expect(job.send(:skip_attachment?, attachment, 'pdf')).to be true
    end

    it 'does not skip image when file_type is image' do
      expect(job.send(:skip_attachment?, attachment, 'image')).to be false
    end

    it 'does not skip image when file_type is empty' do
      expect(job.send(:skip_attachment?, attachment, '')).to be false
    end
  end
end
