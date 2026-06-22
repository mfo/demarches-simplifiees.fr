# frozen_string_literal: true

describe ReleaseNote::FormComponent, type: :component do
  it 'renders the rich text body editor' do
    render_inline(described_class.new(release_note: build(:release_note)))

    expect(page).to have_css('trix-editor')
  end
end
