# frozen_string_literal: true

RSpec.describe Dossiers::RNAComponent, type: :component do
  let(:champ) do
    Champs::RNAChamp.new(external_state:, data: rna_data)
      .tap { |c| allow(c).to receive(:to_s).and_return('W173847273') }
  end

  subject { render_inline(described_class.new(champ:)) }

  before do
    allow(Dossiers::ExternalChampComponent).to receive(:new).and_call_original
    subject
  end

  context 'when the data is fetched?' do
    let(:external_state) { 'fetched' }
    let(:rna_data) do
      {
        'association_titre' => 'LA PRÉVENTION ROUTIÈRE',
        'association_objet' => 'Prévention des accidents de la route',
        'association_date_creation' => '1949-01-01',
      }
    end

    it 'renders ExternalChampComponent with correct arguments' do
      expect(Dossiers::ExternalChampComponent).to have_received(:new) do |data:, details:, source:|
        expect(data).to include(['Numéro RNA', 'W173847273'])
        expect(data).to include(['Nom de l’association', 'LA PRÉVENTION ROUTIÈRE'])
        expect(data).to include(['Objet de l’association', 'Prévention des accidents de la route'])
        expect(details).to include(['Date de création', '1949-01-01'])
        expect(source.to_s).to include('RNA')
      end
    end
  end
end
