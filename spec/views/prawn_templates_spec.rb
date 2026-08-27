# frozen_string_literal: true

describe 'prawn templates' do
  # Top-level `def`s in a template are defined at render time on the shared
  # view class, common to every template of the process. If two templates
  # define a method with the same name, each render redefines it globally:
  # under a multi-threaded server, a template can end up calling the other
  # template's version mid-render (race condition, see Sentry RAILS-MC3).
  it 'do not define top-level methods with the same name in two different templates' do
    method_definitions = Rails.root.glob('app/views/**/*.prawn').flat_map do |path|
      path.readlines.filter_map do |line|
        method_name = line[/\Adef (\w+)/, 1]
        [method_name, path.relative_path_from(Rails.root).to_s] if method_name
      end
    end

    collisions = method_definitions
      .group_by(&:first)
      .transform_values { |definitions| definitions.map(&:last) }
      .filter { |_, templates| templates.many? }

    expect(collisions).to be_empty, <<~MSG
      Some methods are defined in several prawn templates, which causes race conditions in production:
      #{collisions.map { |name, templates| "  #{name}: #{templates.join(', ')}" }.join("\n")}
      Rename them so that each template uses unique method names.
    MSG
  end
end
