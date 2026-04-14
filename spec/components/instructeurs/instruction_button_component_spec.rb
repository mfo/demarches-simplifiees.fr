# frozen_string_literal: true

RSpec.describe Instructeurs::InstructionButtonComponent, type: :component do
  include DossierHelper

  subject(:rendered) do
    render_inline(described_class.new(dossier:, procedure: dossier.procedure))
  end

  context 'when dossier is en_construction' do
    let(:dossier) { create(:dossier, :en_construction) }

    it 'does not render' do
      expect(rendered.to_s).to be_empty
    end
  end

  context 'when dossier is en_instruction' do
    let(:dossier) { create(:dossier, :en_instruction) }

    it 'renders the instruction button and modal content' do
      expect(rendered).to have_button('Rendre une décision')
      expect(rendered).to have_selector('#modal-instruction-button')
      expect(rendered).to have_selector('#modal-instruction-title', text: "Rendre une décision sur le dossier n° #{dossier.id} - #{dossier.owner_name}")

      expect(rendered).to have_text('Accepter le dossier')
      expect(rendered).to have_text('Refuser le dossier')
      expect(rendered).to have_text('Classer sans suite le dossier')

      expect(rendered).to have_selector('[data-state="accept"]')
      expect(rendered).to have_selector('[data-state="refuse"]')
      expect(rendered).to have_selector('[data-state="without-continuation"]')
    end

    it 'renders the motivation fields for each action' do
      expect(rendered).to have_field('motivation_accept', type: 'textarea')
      expect(rendered).to have_field('motivation_refuse', type: 'textarea')
      expect(rendered).to have_field('motivation_without-continuation', type: 'textarea')
    end

    it 'renders the annotation warning hidden by default when there are no errors' do
      expect(rendered).to have_selector(
        '#alert-error-annotation.hidden',
        text: "Les annotations privées n’ont pas été correctement renseignées. Elles sont indispensables à l’instruction du dossier."
      )
    end
  end

  context 'when dossier is en_instruction with invalid mandatory private annotations' do
    let(:procedure) { create(:procedure, types_de_champ_private:) }
    let(:dossier) { create(:dossier, :en_instruction, procedure:) }
    let(:types_de_champ_public) { [] }
    let(:types_de_champ_private) { [{ type: :text, mandatory: true }] }

    subject(:rendered) do
      render_inline(described_class.new(dossier:, procedure:))
    end

    it 'renders the annotation warning visible' do
      expect(rendered).to have_selector(
        '#alert-error-annotation:not(.hidden)',
        text: "Les annotations privées n’ont pas été correctement renseignées. Elles sont indispensables à l’instruction du dossier."
      )
    end
  end

  context 'when rendered in batch mode' do
    let(:procedure) { create(:procedure) }

    subject(:rendered) do
      render_inline(described_class.new(batch: true, procedure:))
    end

    it 'renders the batch instruction button' do
      expect(rendered).to have_button('Rendre une décision', disabled: true)
      expect(rendered).to have_selector('button[data-operation="instruction"]')
      expect(rendered).to have_selector('button[data-action="batch-operation#openInstructionModal"]')
    end

    it 'renders the batch modal content' do
      expect(rendered).to have_selector('#modal-instruction-button')
      expect(rendered).to have_selector('#modal-instruction-title', text: 'Rendre une décision sur les dossiers')

      expect(rendered).to have_text('Accepter les dossiers')
      expect(rendered).to have_text('Refuser les dossiers')
      expect(rendered).to have_text('Classer sans suite les dossiers')
    end

    it 'does not render the annotation warning' do
      expect(rendered).not_to have_selector('#alert-error-annotation')
    end
  end
end
