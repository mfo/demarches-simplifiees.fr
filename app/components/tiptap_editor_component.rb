# frozen_string_literal: true

class TiptapEditorComponent < ApplicationComponent
  attr_reader :form, :field_name, :preview_url

  def initialize(form:, field_name:, preview_url: nil)
    @form = form
    @field_name = field_name
    @preview_url = preview_url
  end

  def input_value
    form.object.tiptap_body_or_default
  end

  def data_attributes
    attributes = { controller: 'tiptap' }
    attributes[:tiptap_preview_url_value] = preview_url if preview_url
    attributes
  end
end
