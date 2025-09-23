# frozen_string_literal: true

require 'nokogiri'
require 'pathname'
require 'fileutils'

describe 'contact/admin', type: :view do
  def snapshot_path(example)
    spec_pathname = Pathname.new(example.metadata[:file_path])
    absolute_spec_path = spec_pathname.absolute? ? spec_pathname : Rails.root.join(spec_pathname)
    spec_relative_path = absolute_spec_path.relative_path_from(Rails.root.join('spec/views'))
    spec_name = spec_relative_path.to_s.sub(/_spec\.rb\z/, '')
    example_name = example.description.parameterize(separator: '_')
    line_number = example.metadata[:line_number]
    filename = "#{spec_name}_it_#{example_name}-#{line_number}.html"

    spec_relative_path.dirname.join('__snapshots__', filename)
  end

  def normalized_structure_for(html)
    fragment = Nokogiri::HTML5.fragment(html)

    normalize_node = lambda do |node|
      if node.element?
        {
          name: node.name,
          attributes: node.attribute_nodes.map(&:name).sort,
          children: node.children.filter_map { |child| normalize_node.call(child) }
        }
      end
    end

    fragment.children.filter_map { |child| normalize_node.call(child) }
  end

  subject(:rendered_page) { render template: 'contact/admin' }

  let(:form) do
    build(
      :contact_form,
      for_admin: true,
      question_type: ContactForm::ADMIN_TYPE_QUESTION
    )
  end

  before do
    Current.application_base_url = 'https://example.test'
    Current.application_name = 'Demarches Simplifiées'

    assign(:form, form)

    view.lookup_context.prefixes << 'application'
    view.lookup_context.prefixes << 'root'
  end

  after { Current.reset }

  it 'renders the admin contact form container' do |example|
    expect(rendered_page).to have_css('#contact-form')

    snapshot_full_path = Rails.root.join('spec/views', snapshot_path(example))

    if ENV['SNAPSHOT'] == '1'
      FileUtils.mkdir_p(snapshot_full_path.dirname)
      File.write(snapshot_full_path, rendered_page)
    end

    if ENV['CHECK_SNAPSHOT'] == '1' && snapshot_full_path.exist?
      expected_structure = normalized_structure_for(snapshot_full_path.read)
      current_structure = normalized_structure_for(rendered_page)

      expect(current_structure).to eq(expected_structure)
    end
  end
end
