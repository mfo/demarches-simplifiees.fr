# frozen_string_literal: true

RSpec.describe Procedure::EmailTemplateCardComponent, type: :component do
  let(:procedure) { create(:procedure) }

  subject(:rendered) { render_inline(described_class.new(email_template:)) }

  context 'when the email is edited with tiptap content (json_subject)' do
    let(:email_template) do
      create(:initiated_mail, procedure:, json_subject: {
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
      expect(rendered).to have_selector('.fr-card__desc', text: 'Accusé pour le dossier numéro du dossier')
      expect(rendered).to have_selector('.fr-card__desc .fr-tag', text: 'numéro du dossier')
    end
  end

  context 'when the email is edited but not yet migrated (legacy subject only)' do
    let(:email_template) { create(:initiated_mail, procedure:) }

    it 'converts the legacy subject tags to styled chips' do
      expect(rendered).to have_selector('.fr-card__desc', text: 'Accusé de réception')
      expect(rendered).to have_selector('.fr-card__desc .fr-tag', text: 'numéro du dossier')
    end
  end

  context 'when the email is a standard (unedited) template' do
    let(:email_template) { Mails::InitiatedMail.default_for_procedure(procedure) }

    it 'renders no description and the standard-model tag' do
      expect(rendered).to have_no_selector('.fr-card__desc')
      expect(rendered).to have_selector('.fr-tag', text: 'Modèle standard')
    end
  end
end
