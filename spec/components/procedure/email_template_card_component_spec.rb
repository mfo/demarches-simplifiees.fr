# frozen_string_literal: true

RSpec.describe Procedure::EmailTemplateCardComponent, type: :component do
  let(:procedure) { procedures.individual }

  subject(:rendered) { render_inline(described_class.new(email_template:)) }

  context 'when the email is edited with tiptap content (json_subject)' do
    let(:email_template) do
      create(:email_depose, procedure:, json_subject: {
        "type" => "doc",
        "content" => [
          {
            "type" => "paragraph", "content" => [
              { "type" => "text", "text" => "Accusé pour le dossier " },
              { "type" => "mention", "attrs" => { "id" => "dossier_number", "label" => "numéro du dossier" } },
            ],
          },
        ],
      })
    end

    it 'renders the subject excerpt with the tag styled as a chip' do
      expect(rendered).to have_text('Accusé pour le dossier numéro du dossier')
      expect(rendered).to have_selector('.fr-tag', text: 'numéro du dossier')
      expect(rendered).to have_selector('.fr-tag.fr-tag--blue-ecume', text: /modifié le/)
    end
  end

  context 'when the email is edited but not yet migrated (legacy subject only)' do
    let(:email_template) { create(:email_depose, procedure:) }

    it 'converts the legacy subject tags to styled chips' do
      expect(rendered).to have_text('Accusé de réception')
      expect(rendered).to have_selector('.fr-tag', text: 'numéro du dossier')
    end
  end

  context 'when the email is a standard (unedited) template' do
    let(:email_template) { Emails::Depose.default_for_procedure(procedure) }

    it 'renders the default subject with tags as chips and the standard-model tag' do
      expect(rendered).to have_text('a bien été déposé')
      expect(rendered).to have_selector('.fr-tag', text: 'numéro du dossier')
      expect(rendered).to have_selector('.fr-tag', text: 'Modèle standard')
      expect(rendered).to have_no_selector('.fr-tag--blue-ecume')
    end

    it 'renders the context description' do
      expect(rendered).to have_text('après qu’il a déposé son dossier')
      expect(rendered).to have_text('Une attestation de dépôt est jointe')
    end
  end
end
