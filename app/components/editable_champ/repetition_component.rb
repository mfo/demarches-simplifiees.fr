# frozen_string_literal: true

class EditableChamp::RepetitionComponent < EditableChamp::EditableChampBaseComponent
  def dsfr_champ_container
    :fieldset
  end

  def legend_params
    @champ.description.present? ? { describedby: dom_id(@champ, :repetition) } : {}
  end

  def notice_params
    @champ.description.present? ? { id: dom_id(@champ, :repetition) } : {}
  end

  def show_toggle_all_button?
    @champ.dossier.revision.children_of(@champ.type_de_champ).size > 1
  end

  def aria_controls
    @champ.row_ids.map { |row_id| "#{@champ.html_id}-#{row_id}-accordion-accordion-content" }.join(' ')
  end

  def expand_row?(row_id, rows_count)
    rows_count == 1 || row_has_errors?(row_id)
  end

  def row_has_errors?(row_id)
    dossier = @champ.dossier
    return false if dossier.errors.empty?

    children_types = dossier.revision.children_of(@champ.type_de_champ)
    public_ids = children_types.map { |tdc| tdc.public_id(row_id) }.to_set

    public_ids.intersect?(errors_public_ids)
  end

  def errors_public_ids
    @errors_public_ids ||= @champ.dossier.errors.map { |error| error.inner_error.base.public_id if error.is_a?(ActiveModel::NestedError) && error.inner_error.base.respond_to?(:public_id) }.compact.to_set
  end
end
