# frozen_string_literal: true

describe 'instructeurs/dossiers/_instruction_selected_form', type: :view do
  subject(:rendered) do
    render partial: 'instructeurs/dossiers/instruction_selected_form',
      locals: {
        dossier: dossier,
        procedure: procedure,
        operation: operation,
        batch: batch,
        dossier_ids: dossier_ids,
        statut: 'suivis',
      }
  end

  let(:procedure) { create(:procedure) }
  let(:dossier) { create(:dossier, :en_instruction, procedure:) }
  let(:dossier_ids) { [] }

  shared_examples 'selected instruction form' do |operation_name, kind, notice_text, required|
    let(:operation) { operation_name }

    context 'unitaire' do
      let(:batch) { false }

      it 'renders the motivation field' do
        expect(rendered).to have_field("motivation_#{operation_name}", type: 'textarea')

        if required
          expect(rendered).to have_selector("textarea#motivation_#{operation_name}[required]")
        else
          expect(rendered).not_to have_selector("textarea#motivation_#{operation_name}[required]")
        end
      end

      if kind
        context 'avec attestation activée' do
          before { create(:attestation_template, procedure:, kind:, activated: true) }

          it 'renders notice and preview link' do
            expect(rendered).to have_text(notice_text)
            expect(rendered).to have_link('Prévisualiser l’attestation')
            expect(rendered).to have_css("a.fr-notice__link[target='_blank']")
          end
        end

        context 'avec attestation désactivée' do
          before { create(:attestation_template, procedure:, kind:, activated: false) }

          it 'does not render notice or preview link' do
            expect(rendered).not_to have_text(notice_text)
            expect(rendered).not_to have_link('Prévisualiser l’attestation')
          end
        end
      else
        it 'does not render attestation notice' do
          expect(rendered).not_to have_link('Prévisualiser l’attestation')
        end
      end
    end

    context 'batch' do
      let(:batch) { true }
      let(:dossier_ids) { [dossier.id] }

      it 'renders the motivation field' do
        expect(rendered).to have_field("motivation_#{operation_name}", type: 'textarea')

        if required
          expect(rendered).to have_selector("textarea#motivation_#{operation_name}[required]")
        else
          expect(rendered).not_to have_selector("textarea#motivation_#{operation_name}[required]")
        end
      end

      if kind
        context 'avec attestation activée' do
          before { create(:attestation_template, procedure:, kind:, activated: true) }

          it 'renders notice without preview link' do
            expect(rendered).to have_text(notice_text)
            expect(rendered).not_to have_link('Prévisualiser l’attestation')
          end
        end

        context 'avec attestation désactivée' do
          before { create(:attestation_template, procedure:, kind:, activated: false) }

          it 'does not render notice or preview link' do
            expect(rendered).not_to have_text(notice_text)
            expect(rendered).not_to have_link('Prévisualiser l’attestation')
          end
        end
      else
        it 'does not render attestation notice' do
          expect(rendered).not_to have_link('Prévisualiser l’attestation')
        end
      end
    end
  end

  context 'accept' do
    it_behaves_like(
      'selected instruction form',
      'accept',
      :acceptation,
      "L’acceptation du dossier génère automatiquement une attestation à télécharger par l’usager",
      false
    )
  end

  context 'refuse' do
    it_behaves_like(
      'selected instruction form',
      'refuse',
      :refus,
      "Le refus du dossier génère automatiquement une attestation à télécharger par l’usager",
      true
    )
  end

  context 'without-continuation' do
    it_behaves_like(
      'selected instruction form',
      'without-continuation',
      nil,
      nil,
      true
    )
  end
end
