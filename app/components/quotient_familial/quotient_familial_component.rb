# frozen_string_literal: true

class QuotientFamilial::QuotientFamilialComponent < ApplicationComponent
  attr_reader :qf_data

  def initialize(qf_data:, with_header: false, champ: nil, for_preview: false)
    @qf_data = qf_data
    @with_header = with_header
    @champ = champ
    @for_preview = for_preview
  end

  def source
    tag.acronym(t(".data.source_api"))
  end

  def data
    return [] if qf_data.nil?

    qf = qf_data["quotient_familial"]
    allocataires = qf_data["allocataires"]
    enfants = qf_data["enfants"]
    adresse = qf_data["adresse"]

    rows = []

    if qf.present?
      rows << [t(".data.quotient_familial", fournisseur: qf['fournisseur']), qf_values(qf)]
    end

    allocataires&.each_with_index do |allocataire, index|
      suffix = allocataires.size > 1 ? " #{index + 1}" : ""

      rows << [t(".data.allocataire", suffix: suffix), individual_values(allocataire)]
    end

    enfants&.each_with_index do |enfant, index|
      suffix = enfants.size > 1 ? " #{index + 1}" : ""

      rows << [t(".data.enfant", suffix: suffix), individual_values(enfant)]
    end

    if adresse.present?
      rows << [t(".data.adresse_famille"), adresse_values(adresse)]
    end

    rows
  end

  def refresh_disabled?
    return true if @for_preview

    @champ.updated_at > Champs::QuotientFamilialChamp::REFRESH_DELAY.ago
  end

  private

  def qf_values(qf)
    {
      t(".data.valeur") => number_with_delimiter(qf["valeur"], delimiter: " "),
      t(".data.periode_effective") => I18n.l(Date.parse(qf["periode_effective"]), format: "%m/%Y"),
    }
  end

  def individual_values(individual)
    [
      [t(".data.nom_naissance"), individual["nom_naissance"]],
      [t(".data.nom_usage"), individual["nom_usage"]],
      [t(".data.prenoms"), individual["prenoms"]],
      [t(".data.date_naissance"), I18n.l(Date.parse(individual["date_naissance"]), format: :short)],
      [t(".data.sexe"), individual["sexe"]],
    ].reject { |_, v| v.nil? }.to_h
  end

  def adresse_values(adresse)
    {
      t(".data.identite_destinataire") => adresse["destinataire"],
      t(".data.adresse") => format_adresse(adresse),
    }
  end

  def format_adresse(adresse)
    [
      adresse["complement_information"],
      adresse["complement_information_geographique"],
      adresse["lieu_dit"],
      adresse["numero_libelle_voie"],
      adresse["code_postal_ville"],
      adresse["pays"],
    ].compact.join(", ")
  end
end
