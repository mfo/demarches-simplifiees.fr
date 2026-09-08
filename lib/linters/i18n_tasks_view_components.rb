# frozen_string_literal: true

require 'i18n/tasks/data/file_system'
require 'i18n/tasks/scanners/relative_keys'

module I18nTasksViewComponents
  # ViewComponent sidecar translations live next to their component, both in the
  # host and in every in-repo engine.
  COMPONENTS_ROOT = %r{(?:\A|/)(?:engines/[^/]+/)?app/components/}
  LOCALES = %w[fr en].freeze

  # The path of a sidecar file, relative to the app/components it lives under.
  def self.relative_to_components_root(path)
    match = COMPONENTS_ROOT.match(path)
    return if match.nil?

    match.post_match
  end

  def self.scope_segments(relative_path)
    segments = relative_path.split('/')
    base = segments.pop.split('.').first
    if !LOCALES.include?(base) && base != segments.last
      segments << base
    end
    segments
  end

  class Data < I18n::Tasks::Data::FileSystem
    register_adapter :yaml, '*.yml', I18n::Tasks::Data::Adapter::YamlAdapter
    register_adapter :json, '*.json', I18n::Tasks::Data::Adapter::JsonAdapter

    def load_file(path)
      tree = super
      return tree if !tree.is_a?(Hash)

      relative = I18nTasksViewComponents.relative_to_components_root(path)
      return tree if relative.nil?

      scope = I18nTasksViewComponents.scope_segments(relative)
      tree.transform_values do |subtree|
        next subtree if subtree.nil? # empty sidecar file ("fr:" with no keys)

        scope.reverse_each.reduce(subtree) { |nested, segment| { segment => nested } }
      end
    end
  end

  module RelativeKeys
    def absolute_key(key, path, **)
      relative = I18nTasksViewComponents.relative_to_components_root(File.expand_path(path))
      return super if !key.start_with?('.') || relative.nil?

      "#{component_scope(relative)}#{key}"
    end

    private

    def component_scope(relative_path)
      segments = relative_path.split('/')
      segments[-1] = segments[-1].sub(/\..*\z/, '').delete_prefix('_')
      segments.pop if segments[-1] == segments[-2]
      segments.join('.')
    end
  end
end

I18n::Tasks::Scanners::RelativeKeys.prepend(I18nTasksViewComponents::RelativeKeys)
