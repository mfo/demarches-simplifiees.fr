# frozen_string_literal: true

class TypesDeChampEditor::ChampPieceJustificativeComponent < TypesDeChampEditor::BaseChampComponent
  delegate :titre_identite?, :rib?, :pj_limit_formats?, to: :type_de_champ

  def render?
    type_de_champ.piece_justificative?
  end

  private

  def nature_dom_id = dom_id(type_de_champ, :nature)

  def natures_for_select
    TypeDeChamp.natures.keys
      .map { |k| [t("activerecord.attributes.type_de_champ.natures.#{k}"), k] }
  end

  def piece_justificative_template_options
    {
      attached_file: type_de_champ.piece_justificative_template,
      auto_attach_url: helpers.auto_attach_url(type_de_champ, procedure_id: procedure.id),
      view_as: :download,
    }
  end

  def format_families
    FORMAT_FAMILIES.keys.map do |key|
      [
        key,
        I18n.t("activerecord.attributes.type_de_champ.format_families.#{key}", default: key.to_s.humanize),
        FORMAT_FAMILY_EXAMPLES[key],
      ]
    end
  end
end
