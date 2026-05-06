# frozen_string_literal: true

class Attachment::ErrorWrapperComponent < ApplicationComponent
  def initialize(with_top_margin: false, id: nil)
    @with_top_margin = with_top_margin
    @id = id
  end

  def call
    tag.div(id: @id, class: class_names('fr-messages-group': true, 'hidden': true, 'fr-mt-2w': @with_top_margin), aria: { live: 'assertive' }, data: { 'attachment-error': true, 'turbo-force': 'browser' })
  end
end
