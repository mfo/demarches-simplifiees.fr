# frozen_string_literal: true

describe 'administrate/application/_pagination', type: :view do
  let(:param_name) { '_page' }

  def render_partial(resources)
    render partial: 'administrate/application/pagination', locals: { resources: resources, param_name: param_name }
    rendered
  end

  context 'when resources uses pagination without count' do
    let(:resources) do
      Class.new do
        include Kaminari::PaginatableWithoutCount

        def self.name
          'ResourcesWithoutCount'
        end

        def current_page
          2
        end

        def prev_page
          1
        end

        def next_page
          3
        end
      end.new
    end

    before do
      allow(view).to receive(:link_to_prev_page).and_return('<a class="prev">Prev</a>'.html_safe)
      allow(view).to receive(:link_to_next_page).and_return('<a class="next">Next</a>'.html_safe)
    end

    it 'renders custom pagination links' do
      expect(render_partial(resources)).to include('prev')
    end
  end

  context 'when resources uses standard pagination' do
    let(:resources) { [] }

    before do
      allow(view).to receive(:paginate).and_return('<nav class="pagination">Page</nav>'.html_safe)
    end

    it 'renders paginate helper output' do
      expect(render_partial(resources)).to include('pagination')
    end
  end
end
