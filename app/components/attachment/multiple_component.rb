# frozen_string_literal: true

# Display a widget for uploading, editing and deleting a file attachment
class Attachment::MultipleComponent < ApplicationComponent
  DEFAULT_MAX_ATTACHMENTS = 10

  renders_one :template

  attr_reader :attached_file
  attr_reader :attachments
  attr_reader :champ
  attr_reader :form_object_name
  attr_reader :max
  attr_reader :view_as
  attr_reader :user_can_destroy
  attr_reader :aria_labelledby
  alias user_can_destroy? user_can_destroy

  delegate :size, :empty?, to: :attachments, prefix: true

  def initialize(champ: nil, attached_file:, form_object_name: nil, view_as: :link, user_can_destroy: true, max: nil, aria_labelledby: nil)
    @champ = champ
    @attached_file = attached_file
    @form_object_name = form_object_name
    @view_as = view_as
    @user_can_destroy = user_can_destroy
    @max = max || DEFAULT_MAX_ATTACHMENTS
    @aria_labelledby = aria_labelledby
    @attachments = attached_file.attachments || []
  end

  def each_attachment(&block)
    @attachments.each_with_index(&block)
  end

  def empty_component_id
    champ.present? ? "attachment-multiple-empty-#{champ.public_id}" : "attachment-multiple-empty-generic"
  end

  def auto_attach_url
    champ.present? ? helpers.auto_attach_url(champ) : '#'
  end
  alias poll_url auto_attach_url

  def poll_context
    return :dossier if champ.present?

    nil
  end

  def show_hint?
    champ.present?
  end

  def describedby_hint_id
    return nil if champ.nil?
    "#{champ.focusable_input_id}-pj-hint"
  end

  def max_file_size
    return TypeDeChamp::IDENTITY_FILE_MAX_SIZE if champ&.titre_identite? || champ&.titre_identite_nature?
    champ&.max_file_size_bytes
  end

  def allowed_formats
    @allowed_formats ||= begin
      raw = champ&.piece_justificative? ? champ.allowed_content_types : []
      extensions = raw.filter_map { |ct| MiniMime.lookup_by_content_type(ct)&.extension }.uniq
      sorted = extensions.sort_by { |e| Attachment::EditComponent::EXTENSIONS_ORDER.index(e) || 999 }
      sorted.size > 5 ? (sorted.first(5) + ['…']) : sorted
    end
  end
end
