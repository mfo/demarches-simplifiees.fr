# frozen_string_literal: true

RSpec.describe Dossiers::ChampUpdatedComponent, type: :component do
  subject { render_inline(described_class.new(updated_at:, seen_at:, updated_by:, source_stream:)) }

  let(:updated_at) { Time.zone.local(2026, 5, 19, 10, 30) }
  let(:seen_at) { nil }
  let(:updated_by) { nil }
  let(:source_stream) { Dossier::MAIN_STREAM }

  context 'when updated_at is nil' do
    let(:updated_at) { nil }

    it 'does not render' do
      expect(subject.to_html).to be_empty
    end
  end

  context 'when updated on usager stream' do
    let(:source_stream) { Dossier::MAIN_STREAM }

    it 'renders the usager source and no tooltip' do
      expect(subject).to have_content('usager')
      expect(subject).not_to have_selector('.fr-tooltip')
    end

    context 'with an updated_by value' do
      let(:updated_by) { 'Jean Dupont' }

      it 'still does not render the tooltip (only shown for instructeur stream)' do
        expect(subject).not_to have_selector('.fr-tooltip')
        expect(subject).not_to have_content('Jean Dupont')
      end
    end
  end

  context 'when updated on instructeur buffer stream' do
    let(:source_stream) { Dossier::INSTRUCTEUR_BUFFER_STREAM }

    it 'renders the instructeur source' do
      expect(subject).to have_content('instructeur')
    end

    context 'with an updated_by value' do
      let(:updated_by) { 'Jean Dupont' }

      it 'renders a tooltip with the updater name' do
        expect(subject).to have_selector('button.fr-btn--tooltip[aria-label="Modifié par"]')
        expect(subject).to have_selector('.fr-tooltip[role="tooltip"]', text: 'Jean Dupont', visible: :all)
      end

      it 'links the tooltip button to the tooltip via aria-describedby' do
        subject
        tooltip = page.find('.fr-tooltip', visible: :all)
        button = page.find('button.fr-btn--tooltip')
        expect(button['aria-describedby']).to eq(tooltip['id'])
      end
    end

    context 'without an updated_by value' do
      let(:updated_by) { nil }

      it 'does not render the tooltip' do
        expect(subject).not_to have_selector('.fr-tooltip', visible: :all)
        expect(subject).not_to have_selector('button.fr-btn--tooltip')
      end
    end
  end

  describe 'new badge styling' do
    let(:source_stream) { Dossier::MAIN_STREAM }

    context 'when updated_at is after seen_at' do
      let(:seen_at) { updated_at - 1.hour }

      it 'applies the new badge class' do
        expect(subject).to have_selector('.fr-badge--new')
      end
    end

    context 'when updated_at is before seen_at' do
      let(:seen_at) { updated_at + 1.hour }

      it 'does not apply the new badge class' do
        expect(subject).not_to have_selector('.fr-badge--new')
      end
    end

    context 'when seen_at is nil' do
      let(:seen_at) { nil }

      it 'does not apply the new badge class' do
        expect(subject).not_to have_selector('.fr-badge--new')
      end
    end
  end
end
