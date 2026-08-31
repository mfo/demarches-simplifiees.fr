# frozen_string_literal: true

if defined?(RuboCop)
  module RuboCop
    module Cop
      module DS
        # `Rails/OutputSafety` never reports a bypass that involves i18n: its
        # `i18n_method?` matcher is a `def_node_search`, so a single `t` anywhere
        # in the subtree exempts the whole expression. That leaves our most
        # common bypasses unreported:
        #
        #   # bad
        #   raw t('.body')
        #   t('.body').html_safe
        #   I18n.t('.body_html').html_safe
        #
        #   # good — the `_html` suffix is the convention:
        #   # `t` marks those translations as html_safe and escapes their
        #   # interpolations, so nothing has to be marked by hand.
        #   t('.body_html')
        #
        #   # good — outside of a view context, where `t` is not available:
        #   ActiveSupport::HtmlSafeTranslation.translate('.body_html')
        class I18nOutputSafety < Base
          MSG = 'Suffix the translation key with `_html` rather than tagging it safe by hand. ' \
                'Outside of a view, use `ActiveSupport::HtmlSafeTranslation.translate`.'

          RESTRICT_ON_SEND = [:html_safe, :raw].freeze

          def_node_matcher :i18n_call?, <<~PATTERN
            (send {nil? (const {nil? cbase} :I18n)} {:t :translate} ...)
          PATTERN

          def on_send(node)
            return unless bypasses_escaping_of_a_translation?(node)

            add_offense(node.loc.selector)
          end
          alias on_csend on_send

          private

          def bypasses_escaping_of_a_translation?(node)
            case node.method_name
            when :html_safe
              !node.arguments? && node.receiver && i18n_call?(node.receiver)
            when :raw
              node.receiver.nil? && node.arguments.one? && i18n_call?(node.first_argument)
            end
          end
        end
      end
    end
  end
end
