# frozen_string_literal: true

describe 'Manager instructeurs', js: true do
  let(:super_admin) { create(:super_admin) }
  let(:instructeur) { create(:instructeur) }

  before { login_as super_admin, scope: :super_admin }

  # Generic regression guard for manager action buttons: they must trigger
  # their HTTP verb (here POST) through the browser. They used to rely on the
  # rails-ujs `data-method` handler, which disappeared when administrate
  # dropped jquery-rails in its 1.0 upgrade — turning every such link into a
  # plain GET and yielding a 404. A controller spec cannot catch this because
  # it posts to the action directly, bypassing the rendered button.
  scenario 'reinviting an instructeur runs the action instead of a GET 404' do
    visit manager_instructeur_path(instructeur)
    click_on 'Réinviter'

    expect(page).to have_text('Instructeur réinvité.')
  end
end
