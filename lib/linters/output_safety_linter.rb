# frozen_string_literal: true

if defined?(HamlLint)
  module HamlLint
    # The HAML counterpart of the herb `erb-no-unsafe-raw` rule: RuboCop does not
    # read templates, and haml-lint's own `RuboCop` linter is disabled, so
    # nothing else looks at the Ruby of our HAML views.
    #
    # When the markup comes from a translation, the fix is the `_html` suffix on
    # the key rather than a manual bypass — see the `DS/I18nOutputSafety` cop.
    class Linter::OutputSafetyLinter < Linter
      include LinterRegistry

      RAW = /\braw[\s(]/
      HTML_SAFE = /\.html_safe\b/

      RAW_MSG = 'Avoid `raw`: it bypasses HTML escaping. Suffix the translation key with `_html`, ' \
                'or build the markup with `tag`/`safe_join`.'
      HTML_SAFE_MSG = 'Avoid `.html_safe`: it bypasses HTML escaping. Suffix the translation key with `_html`, ' \
                      'or build the markup with `tag`/`safe_join`.'

      def visit_tag(node)
        check(node)
      end

      def visit_script(node)
        check(node)
      end

      def visit_silent_script(node)
        check(node)
      end

      private

      def check(node)
        line = document.source_lines[node.line - 1].to_s

        record_lint(node, RAW_MSG) if line.match?(RAW)
        record_lint(node, HTML_SAFE_MSG) if line.match?(HTML_SAFE)
      end
    end
  end
end
