# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dossiers::ChampPrefilledBadgeComponent, type: :component do
  let(:types_de_champ_public) { [{ type: :text }] }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:champ) { dossier.champs.first }

  subject { render_inline(described_class.new(champ:, profile:)) }

  context 'as instructeur' do
    let(:profile) { 'instructeur' }

    context 'when champ is prefilled and modified' do
      before do
        champ.update!(prefilled: true, value: 'modified', prefilled_original_value: { 'value' => 'original' })
      end

      it 'renders warning text' do
        expect(subject).to have_css(".fr-message--warning", text: "Donnée du référentiel modifiée par l’usager")
      end
    end

    context 'when champ is prefilled and not modified' do
      before do
        champ.update!(prefilled: true, value: 'original', prefilled_original_value: { 'value' => 'original' })
      end

      it 'renders verified icon' do
        expect(subject).to have_css(".fr-icon-checkbox-circle-line")
      end
    end

    context 'when champ is not prefilled' do
      it 'does not render' do
        expect(subject.to_html).to be_empty
      end
    end

    context 'when champ has no prefilled_original_value (old dossier)' do
      before do
        champ.update!(prefilled: true, value: 'something')
      end

      it 'does not render' do
        expect(subject.to_html).to be_empty
      end
    end
  end

  context 'as usager' do
    let(:profile) { 'usager' }

    context 'when champ is prefilled and modified' do
      before do
        champ.update!(prefilled: true, value: 'modified', prefilled_original_value: { 'value' => 'original' })
      end

      it 'does not render' do
        expect(subject.to_html).to be_empty
      end
    end
  end
end
