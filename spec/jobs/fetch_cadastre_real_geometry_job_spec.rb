# frozen_string_literal: true

describe FetchCadastreRealGeometryJob, type: :job do
  describe '#perform' do
    let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :carte, options: { cadastres: true } }]) }
    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:champ) { dossier.champ_data.first }
    let!(:geo_area) { create(:geo_area, :cadastre, properties:, champ_data: champ) }
    let(:job) { described_class.new(geo_area) }
    subject { job.perform_now }

    context 'when cadastre lookup works' do
      let(:properties) do
        {
          id: '54084000AC0001',
        }
      end
      it 'fetch geo areas from IGN for proper data', vcr: { cassette_name: :cadastre_ok } do
        expect(GeoArea.cadastre_fetched.count).to eq(0)
        expect { subject }.to change { geo_area.geometry }
        expect(GeoArea.cadastre_fetched.count).to eq(1)
      end

      # The dépôt will trigger the render anyway: no point rendering a map the
      # usager is still putting together.
      it 'does not schedule a static map render on a brouillon', vcr: { cassette_name: :cadastre_ok } do
        expect { subject }.not_to have_enqueued_job(RenderCarteChampJob)
      end

      # The real geometry can land after the dépôt (CRON fallback), in which
      # case the image frozen at dépôt would show the approximate geometry.
      context 'when the dossier is already submitted' do
        let(:dossier) { create(:dossier, :en_construction, procedure:) }

        it 'schedules a new static map render', vcr: { cassette_name: :cadastre_ok } do
          expect { subject }.to have_enqueued_job(RenderCarteChampJob).with(champ)
        end
      end
    end
    context 'when cadastre lookup fails by not found', vcr: { cassette_name: :cadastre_ko } do
      let(:properties) do
        {
          id: '666660000C0001',
        }
      end

      it 'marks geo areas with error status' do
        expect { subject }.to change { geo_area.reload.cadastre_state }.to('cadastre_error')
        expect(geo_area.cadastre_error).to eq('not_found')
      end
    end

    context 'when cadastre lookup fails by argument error', vcr: { cassette_name: :cadastre_argument_error } do
      let(:properties) do
        {
          id: '',
        }
      end

      it 'marks geo areas as not found' do
        expect { subject }.not_to change { geo_area.reload.cadastre_state }
      end

      it 'marks error after max attempts threshold reached' do
        expect(job).to receive(:executions).and_return(FetchCadastreRealGeometryJob::MAX_ATTEMPTS_JOBS).at_least(1)
        expect { subject }.to change { geo_area.reload.cadastre_state }
        expect(geo_area.cadastre_error).to eq('api_error')
      end
    end
  end
end
