# frozen_string_literal: true

class Dossiers::DossierVidePdfComponent < ApplicationComponent
  attr_reader :revision, :procedure

  def initialize(revision:)
    @revision = revision
    @procedure = revision.procedure
  end

  private

  def types_de_champ_public = revision.root_types_de_champ_public

  def organisation = procedure.organisation_name.presence || "En attente de saisie"

  # Empty field to fill in by hand: a bordered box (meaning carried by the preceding label)
  def fillable_box(height: :line)
    tag.div('', class: "box box--#{height}", aria: { hidden: true })
  end

  # Label / fillable area pair
  def fillable_field(label)
    tag.div(class: 'field-pair') do
      safe_join([tag.dt(label), tag.dd(fillable_box)])
    end
  end

  REPETITION_OCCURRENCES = 3

  def render_champ(type_de_champ)
    case type_de_champ.type_champ
    when TypeDeChamp.type_champs.fetch(:header_section)
      safe_join([header_section_heading(type_de_champ), description(type_de_champ)].compact)
    when TypeDeChamp.type_champs.fetch(:explication)
      safe_join([libelle(type_de_champ), tag.div(simple_format(type_de_champ.description), class: 'explication')].compact)
    when TypeDeChamp.type_champs.fetch(:piece_justificative)
      safe_join([
        tag.p('Pièce justificative à joindre en complément du dossier', class: 'label'),
        checkboxes([type_de_champ.libelle]),
        description(type_de_champ),
      ].compact)
    when TypeDeChamp.type_champs.fetch(:yes_no), TypeDeChamp.type_champs.fetch(:checkbox)
      field_with_options(type_de_champ, ['Oui', 'Non'], explanation: 'Cochez la mention applicable')
    when TypeDeChamp.type_champs.fetch(:civilite)
      field_with_options(type_de_champ, [Individual::GENDER_FEMALE, Individual::GENDER_MALE])
    when TypeDeChamp.type_champs.fetch(:drop_down_list)
      if type_de_champ.drop_down_advanced? || too_many_options?(type_de_champ)
        libelle_and_box(type_de_champ)
      else
        field_with_options(type_de_champ, type_de_champ.drop_down_options, explanation: 'Cochez la mention applicable, une seule valeur possible')
      end
    when TypeDeChamp.type_champs.fetch(:multiple_drop_down_list)
      if too_many_options?(type_de_champ)
        libelle_and_box(type_de_champ)
      else
        field_with_options(type_de_champ, type_de_champ.drop_down_options, explanation: 'Cochez la mention applicable, plusieurs valeurs possibles')
      end
    when TypeDeChamp.type_champs.fetch(:linked_drop_down_list)
      linked_field(type_de_champ)
    when TypeDeChamp.type_champs.fetch(:siret)
      establishment(type_de_champ.libelle)
    when TypeDeChamp.type_champs.fetch(:repetition)
      repetition(type_de_champ)
    else
      libelle_and_box(type_de_champ)
    end
  end

  def libelle(type_de_champ) = tag.p(type_de_champ.libelle, class: 'label')

  def description(type_de_champ)
    return if type_de_champ.description.blank?

    tag.div(simple_format(type_de_champ.description), class: 'description')
  end

  # Renders admin-authored rich text (bold, italic, links, line breaks) exactly
  # like the web form does, so the printed form matches the on-screen one.
  def simple_format(text) = render(SimpleFormatComponent.new(text, allow_a: true))

  def libelle_and_box(type_de_champ)
    safe_join([libelle(type_de_champ), description(type_de_champ), fillable_box(height: :block)].compact)
  end

  # A decorative checkbox (aria-hidden) followed by the real meaning-bearing label
  def checkbox(label)
    tag.span(class: 'option') do
      safe_join([tag.span('', class: 'checkbox', aria: { hidden: true }), tag.span(label)])
    end
  end

  def checkboxes(labels)
    tag.ul(class: 'options') { safe_join(labels.map { |l| tag.li(checkbox(option_label(l))) }) }
  end

  def field_with_options(type_de_champ, options, explanation: nil)
    explanation_tag = tag.p(explanation, class: 'explanation') if explanation
    safe_join([libelle(type_de_champ), description(type_de_champ), explanation_tag, checkboxes(options)].compact)
  end

  def linked_field(type_de_champ)
    items = type_de_champ.primary_options.compact_blank.flat_map do |primary|
      secondaries = type_de_champ.secondary_options[primary].to_a.compact_blank
      [tag.li(checkbox(primary))] +
        secondaries.map { |s| tag.li(checkbox(s), class: 'secondary') }
    end
    safe_join([libelle(type_de_champ), tag.ul(safe_join(items), class: 'options')])
  end

  def establishment(label)
    safe_join([
      tag.p(label, class: 'label'),
      fillable_field('SIRET'),
      fillable_field('Dénomination'),
      fillable_field('Forme juridique'),
    ])
  end

  def repetition(type_de_champ)
    children = revision.children_of(type_de_champ)
    occurrences = Array.new(REPETITION_OCCURRENCES) do
      safe_join(children.map { |child| tag.section(render_champ(child), class: 'champ') })
    end
    safe_join([libelle(type_de_champ), *occurrences])
  end

  # drop_down_options may contain Strings or [text, value] pairs
  def option_label(option) = option.is_a?(Array) ? option.first : option

  # Past this many options the web form switches to a searchable combobox, so
  # listing every option on paper would span pages: fall back to a write-in box.
  def too_many_options?(type_de_champ)
    type_de_champ.drop_down_options.size >= Champs::DropDownListChamp::THRESHOLD_NB_OPTIONS_AS_AUTOCOMPLETE
  end
end
