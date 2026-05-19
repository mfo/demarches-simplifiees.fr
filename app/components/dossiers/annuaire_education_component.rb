# frozen_string_literal: true

class Dossiers::AnnuaireEducationComponent < ApplicationComponent
  attr_reader :champ

  def initialize(champ:)
    @champ = champ
  end

  def call
    render Dossiers::ExternalChampComponent.new(data:, details:, source:)
  end

  private

  def data
    return [] if champ.data.blank?

    [
      [t('.nom_etablissement'), champ.data['nom_etablissement']],
      [t('.identifiant_etablissement'), champ.data['identifiant_de_l_etablissement']],
      [t('.siren_siret'), champ.data['siren_siret']],
    ]
  end

  def details
    return [] if champ.data.blank?

    [
      [t('.commune'), commune],
      [t('.academie'), "#{champ.data['libelle_academie']} (#{champ.data['code_academie']})"],
      [t('.nature_etablissement'), "#{champ.data['libelle_nature']} (#{champ.data['code_nature']})"],
      [t('.type_contrat_prive'), type_de_contrat],
      [t('.nombre_eleves'), champ.data['nombre_d_eleves']],
      [t('.adresse'), adresse],
      [t('.telephone'), champ.data['telephone']],
      [t('.email'), champ.data['mail']],
      [t('.site_internet'), champ.data['web']],
    ]
  end

  def commune
    if champ.data['nom_commune'].present? && champ.data['code_commune'].present?
      "#{champ.data['nom_commune']} (#{champ.data['code_commune']})"
    elsif champ.data['nom_commune'].present?
      champ.data['nom_commune']
    else
      t('.non_renseignee')
    end
  end

  def source = t('.source')

  def type_de_contrat
    champ.data['type_contrat_prive'] if champ.data['type_contrat_prive'] != 'SANS OBJET'
  end

  def adresse
    safe_join([
      champ.data['adresse_1'],
      champ.data.values_at('code_postal', 'nom_commune').compact_blank.join(" "),
      region_libelle_and_code(champ.data),
    ].compact, tag.br)
  end

  def region_libelle_and_code(data)
    if data['libelle_region'].present? && data['code_region'].present?
      "#{data['libelle_region']} (#{data['code_region']})"
    elsif data['libelle_region'].present?
      data['libelle_region']
    end
  end
end
