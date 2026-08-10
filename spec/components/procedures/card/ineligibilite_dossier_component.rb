# frozen_string_literal: true

describe Procedure::Card::IneligibiliteDossierComponent, type: :component do
  describe 'render' do
    subject do
      render_inline(described_class.new(procedure: procedure))
    end

    context 'when none of public_type_de_champs supports conditional' do
      let(:procedure) { create(:procedure, public_type_de_champs: []) }

      it 'render missing setup' do
        subject
        expect(page).to have_text('Champs manquant')
      end
    end

    context 'when at least one of public_type_de_champs support conditional' do
      let(:procedure) { create(:procedure, public_type_de_champs: [{ type: :yes_no }]) }

      it 'render the template' do
        subject
        expect(page).to have_text('À configurer')
      end
    end
  end
end
