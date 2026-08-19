# frozen_string_literal: true

class TypesDeChamp::DropDownListTypeDeChamp < TypeDeChamp
  def self.category = CHOICE
  def self.editable_option_keys = [:drop_down_other, :drop_down_options, :drop_down_mode]
  def self.column_type = :enum
  def self.simple_routable? = true

  def prefillable? = true
  def options_for_select = options_for_select_with_other
  def choice_type? = true
  def any_drop_down_list? = true
  def customizable? = true

  before_validation :set_default_drop_down_options, if: :type_champ_changed?

  def typed_champ_value(champ)
    if drop_down_advanced? && champ.respond_to?(:referentiel) && champ.referentiel.present?
      path = champ.referentiel_headers&.first&.second
      champ.referentiel_item_value(path)
    else
      super
    end
  end

  def typed_champ_value_for_export(champ, path = :value)
    if drop_down_advanced? && path != :value
      champ.referentiel_item_value(path)
    else
      super
    end
  end

  def typed_champ_value_for_tag(champ, path = :value)
    if drop_down_advanced? && path != :value
      champ.referentiel_item_value(path)
    else
      super
    end
  end

  def columns(procedure_id:, displayable: true, prefix: nil)
    if drop_down_advanced?
      referentiel_columns = if referentiel.present?
        referentiel.headers_with_path.map do |(header, path)|
          options_for_select = referentiel.options_for_path(path)

          if drop_down_other?
            options_for_select << [I18n.t('shared.champs.drop_down_list.other'), Champs::DropDownListChamp::OTHER]
          end

          Columns::JSONPathColumn.new(
            procedure_id:,
            stable_id:,
            tdc_type: type_champ,
            label: "#{libelle_with_prefix(prefix)} – Référentiel #{header}",
            type: :enum,
            jsonpath: "$.referentiel.data.row.#{path}",
            displayable:,
            options_for_select:,
            mandatory: mandatory?
          )
        end
      else
        []
      end

      super + referentiel_columns
    else
      super
    end
  end

  def paths
    if drop_down_advanced? && referentiel.present?
      referentiel.headers_with_path.map do |(header, path)|
        {
          libelle: "#{libelle} (#{header})",
          description: "#{description} (#{header})",
          path:,

        }
      end
    else
      super
    end
  end

  private

  def set_default_drop_down_options
    if drop_down_options.empty?
      self.drop_down_options = ['Fromage', 'Dessert']
    end
  end
end
