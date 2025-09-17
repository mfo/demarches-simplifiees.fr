# frozen_string_literal: true

describe 'administrateurs/_breadcrumbs.html.haml', type: :view do
  let(:steps) { [['Accueil', '/']] }

  before do
    allow(view).to receive(:root_path).and_return('/')
    allow(view).to receive(:current_page?).and_return(false)

    render partial: 'administrateurs/breadcrumbs', locals: { steps: steps }
  end

  it 'renders the breadcrumb navigation' do
    expect(rendered).to have_selector('nav.fr-breadcrumb')
    expect(rendered).to include('Accueil')
  end
end
