# frozen_string_literal: true

RSpec.describe LLM::HeaderComponent::AccordionContentComponent, type: :component do
  subject(:rendered_component) { render_inline(described_class.new) }

  it 'renders the emphasis markup instead of escaping it' do
    expect(rendered_component).to have_selector('li strong', text: 'libellés et descriptions des champs')
    expect(rendered_component).to have_selector('li strong', text: 'structure du formulaire')
    expect(rendered_component).to have_selector('li strong', text: 'bonne utilisation des types de champs')
    expect(rendered_component).to have_selector('li strong', text: 'demande unique d’information')
    expect(rendered_component.to_html).not_to include('&lt;strong&gt;')
  end

  it 'renders the english sidecar' do
    I18n.with_locale(:en) do
      html = render_inline(described_class.new).to_html

      expect(html).to include('<strong>field labels and descriptions</strong>')
      expect(html).not_to include('translation missing')
    end
  end
end
