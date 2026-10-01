# frozen_string_literal: true

describe Dsfr::InputStatusMessageComponent, type: :component do
  let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :piece_justificative, nature: 'rib' }]) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:champ) { dossier.champ_data.first }

  describe 'announcement mode' do
    context 'when the RIB analysis is pending' do
      before { champ.update_column(:external_state, :waiting_for_job) }

      it 'renders only the status text (no .fr-messages-group wrapper)' do
        render_inline(described_class.new(champ:, as_announcement: true))
        expect(page).to have_text('Contenu du fichier en cours')
        expect(page).not_to have_css('.fr-messages-group')
      end
    end

    context 'when the champ is idle (no status to announce)' do
      it 'renders nothing' do
        render_inline(described_class.new(champ:, as_announcement: true))
        expect(page).not_to have_text('Contenu du fichier')
        expect(page).not_to have_css('.fr-messages-group')
      end
    end
  end

  describe 'visible mode aria-live' do
    let(:no_error_component) { double('champ_component', errors_on_attribute?: false, error_full_messages: [], attribute: :value) }
    let(:error_component) { double('champ_component', errors_on_attribute?: true, error_full_messages: ['est invalide'], attribute: :value) }

    context 'with a status message and no validation error' do
      before { champ.update_column(:external_state, :waiting_for_job) }

      it 'drops aria-live (the sr-only region announces the status instead)' do
        render_inline(described_class.new(champ:, champ_component: no_error_component))
        expect(page).to have_css('.fr-messages-group')
        expect(page).not_to have_css('.fr-messages-group[aria-live]')
      end
    end

    context 'with a validation error' do
      it 'keeps aria-live="assertive" for the error' do
        render_inline(described_class.new(champ:, champ_component: error_component))
        expect(page).to have_css('.fr-messages-group[aria-live="assertive"]')
      end
    end
  end

  describe 'an annotation referentiel locked until instruction' do
    let(:procedure) do
      create(:procedure,
             public_type_de_champs: [{ type: :text, libelle: 'Nom', stable_id: 99 }],
             private_type_de_champs: [
               {
                 type: :referentiel,
                 stable_id: 88,
                 referentiel: create(:api_referentiel, :exact_match),
                 referentiel_mapping: { "$.nom" => { prefill: "1", prefill_stable_id: 99, type: "string" } },
               },
             ])
    end
    let(:dossier) { create(:dossier, :en_construction, procedure:) }
    let(:champ) { dossier.champ_data.find { it.stable_id == 88 } }

    context 'while nothing has been fetched' do
      it 'explains why the input is greyed out' do
        render_inline(described_class.new(champ:, as_announcement: true))

        expect(page).to have_text('une fois le dossier passé en instruction')
      end
    end

    context 'when a reference was already found' do
      before { champ.update_columns(external_id: 'JE-VALIDE', value: 'JE-VALIDE', external_state: 'fetched') }

      it 'keeps showing the result rather than the lock' do
        render_inline(described_class.new(champ:, as_announcement: true))

        expect(page).to have_text('Référence trouvée : JE-VALIDE')
        expect(page).not_to have_text('une fois le dossier passé en instruction')
      end
    end
  end

  describe 'a degraded siret champ' do
    let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :siret }]) }

    before do
      champ.update_columns(external_id: '30613890001294', value: '30613890001294', external_state: 'degraded')
    end

    it 'tells the user their SIRET is kept, instead of staying silent' do
      render_inline(described_class.new(champ:, as_announcement: true))

      expect(page).to have_text('306 138 900 01294')
      expect(page).to have_text('vous pouvez continuer')
    end
  end

  describe 'a degraded rna champ' do
    let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :rna }]) }

    before do
      champ.update_columns(external_id: 'W182736273', value: 'W182736273', external_state: 'degraded')
    end

    it 'tells the user their RNA is kept, instead of announcing an empty success' do
      render_inline(described_class.new(champ:, as_announcement: true))

      expect(page).to have_text('W182736273')
      expect(page).to have_text('vous pouvez continuer')
    end
  end
end
