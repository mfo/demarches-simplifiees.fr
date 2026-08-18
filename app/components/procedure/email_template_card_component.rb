# frozen_string_literal: true

class Procedure::EmailTemplateCardComponent < ApplicationComponent
  def initialize(email_template:)
    @email_template = email_template
  end

  private

  def procedure
    @email_template.procedure
  end

  def slug
    @email_template.class.const_get(:SLUG)
  end

  def title
    @email_template.class.const_get(:DISPLAYED_NAME)
  end

  def subject_preview
    subject_doc = @email_template.tiptap_subject_doc.deep_symbolize_keys
    sanitize(TiptapService.new.to_texts_and_tags(subject_doc, strip: false))
  end

  def description
    t(".descriptions.#{slug}.default")
  end

  def error
    @email_template.errors.full_messages.first if @email_template.errors.present?
  end

  def tag_label
    if edited?
      "modifié le #{l(@email_template.updated_at.to_date, format: :short)}"
    else
      "Modèle standard"
    end
  end

  def edited?
    @email_template.updated_at.present?
  end

  def edit_path
    edit_admin_procedure_email_template_path(procedure, slug)
  end

  def final_decision_templates
    [Emails::ClasseSansSuite.const_get(:SLUG), Emails::Refuse.const_get(:SLUG), Emails::Accepte.const_get(:SLUG)]
  end

  def not_editable?
    procedure.accuse_lecture? && final_decision_templates.include?(slug)
  end
end
