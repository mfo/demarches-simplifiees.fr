# frozen_string_literal: true

module TurboStreamHelper
  def turbo_stream
    TagBuilder.new(self)
  end

  class TagBuilder < Turbo::Streams::TagBuilder
    include ActionView::Helpers::TagHelper

    attr_reader :view_context

    def show(target, delay: nil)
      turbo_stream_action_tag :show, target:, delay:
    end

    def show_all(targets, delay: nil)
      turbo_stream_action_tag :show, targets:, delay:
    end

    def hide(target, delay: nil)
      turbo_stream_action_tag :hide, target:, delay:
    end

    def hide_all(targets, delay: nil)
      turbo_stream_action_tag :hide, targets:, delay:
    end

    def focus(target, delay: nil)
      turbo_stream_action_tag :focus, target:, delay:
    end

    def focus_all(targets, delay: nil)
      turbo_stream_action_tag :focus, targets:, delay:
    end

    def enable(target, delay: nil)
      turbo_stream_action_tag :enable, target:, delay:
    end

    def enable_all(targets, delay: nil)
      turbo_stream_action_tag :enable, targets:, delay:
    end

    def disable(target, delay: nil)
      turbo_stream_action_tag :disable, target:, delay:
    end

    def disable_all(targets, delay: nil)
      turbo_stream_action_tag :disable, targets:, delay:
    end

    def append(target, content = nil, delay: nil, **, &block)
      if delay
        turbo_stream_action_tag :append, target:, delay:, template: content || view_context.capture(&block)
      else
        super(target, content, **, &block)
      end
    end

    def refresh
      turbo_stream_action_tag :refresh
    end

    def dispatch(type, detail = nil)
      content = detail.present? ? tag.script(cdata_section(detail.to_json), type: 'application/json') : nil
      action_all :append, 'head', tag.dispatch_event(content, type:)
    end
  end
end
