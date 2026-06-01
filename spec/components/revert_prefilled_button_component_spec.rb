# frozen_string_literal: true

require "rails_helper"

RSpec.describe EditableChamp::RevertPrefilledButtonComponent, type: :component do
  let(:types_de_champ_public) { [{ type: :text }] }
  let(:procedure) { create(:procedure, types_de_champ_public:) }
  let(:dossier) { create(:dossier, procedure:) }
  let(:champ) { dossier.champ_data.first }

  subject { render_inline(described_class.new(champ:)) }

  context 'when champ is prefilled and modified' do
    before do
      champ.update!(prefilled: true, value: 'modified', prefilled_original_value: { 'value' => 'original' })
    end

    it 'renders the revert button' do
      expect(subject).to have_button("Remplir à nouveau automatiquement")
    end
  end

  context 'when champ is prefilled but not modified' do
    before do
      champ.update!(prefilled: true, value: 'original', prefilled_original_value: { 'value' => 'original' })
    end

    it 'does not render' do
      expect(subject.to_html).to be_empty
    end
  end

  context 'when champ is not prefilled' do
    it 'does not render' do
      expect(subject.to_html).to be_empty
    end
  end

  context 'when champ is private (annotation)' do
    let(:types_de_champ_private) { [{ type: :text }] }
    let(:procedure) { create(:procedure, types_de_champ_private:) }
    let(:champ) { dossier.champ_data.find(&:private?) }

    before do
      champ.update!(prefilled: true, value: 'modified', prefilled_original_value: { 'value' => 'original' })
    end

    it 'does not render' do
      expect(subject.to_html).to be_empty
    end
  end

  context 'when champ is on instructeur buffer stream' do
    before do
      champ.update!(prefilled: true, value: 'modified', prefilled_original_value: { 'value' => 'original' }, stream: Dossier::INSTRUCTEUR_BUFFER_STREAM)
    end

    it 'does not render' do
      expect(subject.to_html).to be_empty
    end
  end
end
