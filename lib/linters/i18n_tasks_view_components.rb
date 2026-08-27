# frozen_string_literal: true

# Teaches i18n-tasks about ViewComponent sidecar translations.
# Loaded from config/i18n-tasks.yml (ERB header); never loaded by the Rails app
# (lib/linters is excluded from autoloading in config/application.rb).
#
# Sidecar YAML files (app/components/foo/bar_component/{bar_component.,}fr.yml)
# contain locale-relative keys: ViewComponent::Translatable prefixes the
# component scope ("foo.bar_component") at runtime. Both the data adapter and
# the relative-key resolution below mirror that convention.

require 'i18n/tasks/data/file_system'
require 'i18n/tasks/scanners/relative_keys'

module I18nTasksViewComponents
  COMPONENTS_ROOT = 'app/components'
  LOCALES = %w[fr en].freeze

  # Derives the component i18n scope from any of the sidecar layouts
  # ViewComponent supports:
  #   foo/bar_component.fr.yml                    => ["foo", "bar_component"]
  #   foo/bar_component/bar_component.fr.yml      => ["foo", "bar_component"]
  #   foo/bar_component/bar_component.html.fr.yml => ["foo", "bar_component"]
  #   foo/bar_component/fr.yml                    => ["foo", "bar_component"]
  def self.scope_segments(yml_path)
    segments = yml_path.delete_prefix("#{COMPONENTS_ROOT}/").split('/')
    base = segments.pop.split('.').first
    if !LOCALES.include?(base) && base != segments.last
      segments << base
    end
    segments
  end

  # Nests each sidecar file's tree under its component scope, so that
  # "fr: { legend: ... }" is read as "fr.foo.bar_component.legend".
  class Data < I18n::Tasks::Data::FileSystem
    # Adapter registrations live in a class-level ivar and are not inherited.
    register_adapter :yaml, '*.yml', I18n::Tasks::Data::Adapter::YamlAdapter
    register_adapter :json, '*.json', I18n::Tasks::Data::Adapter::JsonAdapter

    def load_file(path)
      tree = super
      return tree if !tree.is_a?(Hash) || !path.start_with?("#{COMPONENTS_ROOT}/")

      scope = I18nTasksViewComponents.scope_segments(path)
      tree.transform_values do |subtree|
        next subtree if subtree.nil? # empty sidecar file ("fr:" with no keys)

        scope.reverse_each.reduce(subtree) { |nested, segment| { segment => nested } }
      end
    end
  end

  # Resolves t('.key') in component files to the ViewComponent scope. The
  # default path-based resolution would double the component name for
  # templates living inside their sidecar directory
  # (bar_component/bar_component.html.erb => "bar_component.bar_component").
  module RelativeKeys
    ABSOLUTE_ROOT = File.expand_path(COMPONENTS_ROOT)

    def absolute_key(key, path, **)
      expanded = File.expand_path(path)
      return super if !key.start_with?('.') || !expanded.start_with?("#{ABSOLUTE_ROOT}/")

      "#{component_scope(expanded)}#{key}"
    end

    private

    def component_scope(expanded_path)
      segments = expanded_path.delete_prefix("#{ABSOLUTE_ROOT}/").split('/')
      segments[-1] = segments[-1].sub(/\..*\z/, '').delete_prefix('_')
      segments.pop if segments[-1] == segments[-2]
      segments.join('.')
    end
  end
end

I18n::Tasks::Scanners::RelativeKeys.prepend(I18nTasksViewComponents::RelativeKeys)
