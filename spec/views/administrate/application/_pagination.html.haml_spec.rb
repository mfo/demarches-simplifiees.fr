# frozen_string_literal: true

describe 'administrate/application/_pagination.html.haml', type: :view do
  let(:resources) { Kaminari.paginate_array(%w[a b c]).page(1).per(1) }

  before do
    allow(view).to receive(:paginate).and_return('<nav class="pagination"></nav>'.html_safe)
  end

  it 'renders pagination container' do
    render partial: 'administrate/application/pagination', locals: { resources: resources }

    expect(rendered).to have_selector('nav.pagination')
  end
end
