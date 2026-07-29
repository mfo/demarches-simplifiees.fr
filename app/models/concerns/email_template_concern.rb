# frozen_string_literal: true

module EmailTemplateConcern
  extend ActiveSupport::Concern

  include TagsSubstitutionConcern

  module Actions
    SHOW         = :show
    ASK_QUESTION = :ask_question
    REPLY        = :reply
  end

  def subject_for_dossier(dossier)
    if json_subject.present?
      render_tiptap_text(json_subject, dossier)
    else
      replace_tags(subject, dossier, escape: false).presence || replace_tags(self.class::DEFAULT_SUBJECT, dossier, escape: false)
    end
  end

  def body_for_dossier(dossier)
    if json_body.present?
      render_tiptap_html(json_body, dossier)
    else
      replace_tags(body, dossier)
    end
  end

  def actions_for_dossier(dossier)
    [EmailTemplateConcern::Actions::SHOW, EmailTemplateConcern::Actions::ASK_QUESTION]
  end

  def attachment_for_dossier(dossier)
    nil
  end

  def tiptap_body
    json_body&.to_json
  end

  def tiptap_body=(json)
    self.json_body = JSON.parse(json)
  end

  def tiptap_subject
    json_subject&.to_json
  end

  def tiptap_subject=(json)
    self.json_subject = JSON.parse(json)
  end

  # The current tiptap document as a Hash: the stored one, or the legacy
  # body/subject converted on the fly (for templates not yet migrated).
  def tiptap_body_doc
    json_body.presence || legacy_html_to_tiptap(body)
  end

  def tiptap_body_or_default
    tiptap_body_doc.to_json
  end

  def tiptap_subject_doc
    json_subject.presence || {
      "type" => "doc",
      "content" => [{ "type" => "paragraph", "content" => tiptap_inline_nodes_for(subject.presence || self.class::DEFAULT_SUBJECT) }],
    }
  end

  def tiptap_subject_or_default
    tiptap_subject_doc.to_json
  end

  included do
    validates :json_body, tags: true, if: -> { json_body.present? }
    validates :json_subject, tags: true, if: -> { json_subject.present? }
    validates :body, tags: true, if: -> { json_body.blank? }
    validates :subject, tags: true, if: -> { json_subject.blank? }

    # In the transaction of the write itself: email_templates can never drift
    # from the legacy tables, even for a few minutes.
    after_save { EmailTemplateReplica.replicate(self) }
    after_destroy { EmailTemplateReplica.delete_replica(self) }
  end

  class_methods do
    def default_for_procedure(procedure)
      template_name = default_template_name_for_procedure(procedure)
      body = ActionController::Base.render(template: template_name).gsub(/<!--.*?-->/m, '')
      body = body.gsub(/(?<!^|[.-])(?<!<\/strong>)\n/, ' ')
      new(subject: const_get(:DEFAULT_SUBJECT), body:, procedure:)
    end

    def default_template_name_for_procedure(procedure)
      const_get(:DEFAULT_TEMPLATE_NAME)
    end
  end

  def tiptap_inline_nodes_for(text)
    return [] if text.nil?

    parse_tags(text).filter_map do |token|
      case token
      in { tag:, id: }
        { "type" => "mention", "attrs" => { "id" => id, "label" => tag } }
      in { tag: }
        { "type" => "text", "text" => "--#{tag}--" }
      in { text: }
        { "type" => "text", "text" => text } unless text.empty?
      else
        nil
      end
    end
  end

  def dossier_tags
    super + TagsSubstitutionConcern::DOSSIER_TAGS_FOR_MAIL
  end

  private

  def legacy_html_to_tiptap(html)
    memoize_tags_by_libelle do
      TrixToTiptapService.new(inline_resolver: method(:tiptap_inline_nodes_for)).to_document(html)
    end
  end

  def render_tiptap_html(json, dossier)
    node = json.deep_symbolize_keys
    TiptapService.new.to_html(node, tiptap_substitutions(node, dossier, escape: true))
  end

  def render_tiptap_text(json, dossier)
    node = json.deep_symbolize_keys
    TiptapService.new.to_texts_and_tags(node, tiptap_substitutions(node, dossier, escape: false), strip: false)
  end

  # `memoize:` shares the tag values between the subject and the body of one email.
  def tiptap_substitutions(node, dossier, escape:)
    used = TiptapService.used_tags_and_libelle_for(node)
    tags_substitutions(used, dossier, escape:, memoize: true)
  end
end
