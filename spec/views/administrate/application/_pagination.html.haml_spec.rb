# frozen_string_literal: true

require 'rails_helper'

describe 'administrate/application/pagination', type: :view do
  let(:previous_link) { '<a class="prev">Précédent</a>'.html_safe }
  let(:next_link) { '<a class="next">Suivant</a>'.html_safe }

  before do
    allow(view).to receive(:paginate).and_return('<nav class="pagination">content</nav>'.html_safe)
    allow(view).to receive(:link_to_prev_page).and_return(previous_link)
    allow(view).to receive(:link_to_next_page).and_return(next_link)
  end

  def paginated_array
    array = Kaminari.paginate_array((1..10).to_a).page(2).per(2)
    array.define_singleton_method(:loaded?) { true }
    array
  end

  it 'renders paginate for standard resources' do
    render partial: 'administrate/application/pagination', locals: { resources: paginated_array }

    expect(rendered).to include('pagination')
  end

  it 'renders navigation when resources are without count' do
    resources = paginated_array
    resources.singleton_class.include(Kaminari::PaginatableWithoutCount)

    render partial: 'administrate/application/pagination', locals: { resources: resources }

    expect(rendered).to include('pagination')
  end
end
