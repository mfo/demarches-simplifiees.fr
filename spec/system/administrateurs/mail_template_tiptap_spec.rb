# frozen_string_literal: true

describe 'As an administrateur i can edit a mail template with the tiptap editor', js: true do
  let(:administrateur) { create(:administrateur, user: create(:user)) }
  let(:procedure) { create(:procedure, :with_type_de_champ, administrateurs: [administrateur]) }

  before { login_as administrateur.user, scope: :user }

  scenario 'Mail template tiptap editor' do
    visit edit_admin_procedure_mail_template_path(procedure, 'received_mail')

    expect(page).to have_css('.tiptap-editor')
    expect(page).to have_button('Italique')
    expect(page).to have_button('Saut de ligne')

    # The default template body (Trix HTML + `--tags--`, including a `<br>`) must be
    # converted and loaded into the editor, not silently dropped as invalid content.
    within('#mails_received_mail_tiptap_body_editor') do
      expect(page).to have_content('Bonjour')
      expect(page).to have_css('.fr-tag', text: 'numéro du dossier')
    end

    within('#mail-body-preview') { expect(page).to have_css('iframe') }

    body_group = find('.fr-input-group', text: 'Corps de l’email')
    within(body_group) do
      find('button[data-tag-id="dossier_number"]').click
    end

    within('#mails_received_mail_tiptap_body_editor') do
      expect(page).to have_css('.fr-tag', text: 'numéro du dossier')
    end

    # The subject offers the same tags, hidden behind a show/hide toggle.
    click_on 'Balises disponibles'
    within('#mails_received_mail_tiptap_subject_tags') do
      find('button[data-tag-id="dossier_number"]').click
    end
    within('#mails_received_mail_tiptap_subject_editor') do
      expect(page).to have_css('.fr-tag', text: 'numéro du dossier')
    end

    click_on 'Enregistrer'
    expect(page).to have_content('Email mis à jour')

    mail = procedure.reload.received_mail
    expect(mail.json_body).to be_present
    expect(TiptapService.used_tags_and_libelle_for(mail.json_body.deep_symbolize_keys).map(&:first)).to include('dossier_number')
    expect(TiptapService.used_tags_and_libelle_for(mail.json_subject.deep_symbolize_keys).map(&:first)).to include('dossier_number')
  end
end
