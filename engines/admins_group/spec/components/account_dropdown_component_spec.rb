# frozen_string_literal: true

# The account dropdown loops over NavBarProfile and looks the label up by
# profile name, so the gestionnaire entry is the engine's to cover.
describe AccountDropdownComponent, type: :component do
  let(:component) { described_class.new(dossier: nil, nav_bar_profile: :user) }
  let(:gestionnaire) { create(:gestionnaire) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(gestionnaire.user)
    allow_any_instance_of(ApplicationController).to receive(:super_admin_signed_in?).and_return(false)
    allow_any_instance_of(ApplicationController).to receive(:gestionnaire_signed_in?).and_return(true)
  end

  subject { render_inline(component) }

  it 'offers to switch to the gestionnaire profile' do
    expect(subject).to have_link('Passer en gestionnaire')
    expect(subject.to_html).to include(%(href="#{component.helpers.gestionnaire_groupe_gestionnaires_path}"))
  end
end
