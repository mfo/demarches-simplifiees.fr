# frozen_string_literal: true

# see: https://www.systeme-de-design.gouv.fr/elements-d-interface/composants/bandeau-d-information-importante/
class Dsfr::NoticeComponent < ApplicationComponent
  renders_one :title
  renders_one :desc
  renders_one :link

  attr_reader :data_attributes, :extra_class_names

  def initialize(closable: false, state: 'info', data_attributes: {}, extra_class_names: nil)
    @closable = closable
    @data_attributes = data_attributes
    @state = state
    @extra_class_names = extra_class_names
  end

  def options
    attrs = notice_data_attributes
    attrs.merge(class: class_names(attrs[:class], "fr-notice", "fr-notice--#{@state}", @extra_class_names))
  end

  def closable?
    !!@closable
  end

  def notice_data_attributes
    { "data-controller": 'dsfr-notice', "data-dsfr-notice-target": "notice" }.merge(data_attributes)
  end
end
