# frozen_string_literal: true

class Dossiers::ChangesComponentPreview < ViewComponent::Preview
  def default
    changed_columns = [
      changed_column(label: "Votre région d'intervention", type: :enum, value: 'Bourgogne-Franche-Comté', previous_value: 'Île-de-France'),
      changed_column(label: 'Adresse de correspondance', type: :text, value: '47 Rue Le Peletier 75009 Paris', previous_value: '12 Rue de Rivoli 75001 Paris'),
      changed_column(label: 'Domaine culturel et artistique principal', type: :enum, value: 'Musique', previous_value: 'Théâtre'),
    ]

    render Dossiers::ChangesComponent.new(changed_columns:)
  end

  def all_types
    changed_columns = [
      changed_column(label: 'Texte', type: :text, value: 'Nouvelle valeur', previous_value: 'Ancienne valeur'),
      changed_column(label: 'Nombre', type: :integer, value: 42, previous_value: 12),
      changed_column(label: 'Date', type: :date, value: Date.new(2026, 6, 16), previous_value: Date.new(2026, 1, 1)),
      changed_column(label: 'Case à cocher', type: :boolean, value: true, previous_value: false),
      changed_column(label: 'Champ vidé', type: :text, value: nil, previous_value: 'Valeur précédente'),
      changed_column(label: 'Choix multiples', type: :enums, value: ['Musique', 'Danse', 'Cirque', 'Cinéma'], previous_value: ['Musique', 'Théâtre', 'Photographie']),
      changed_column(label: 'Pièces justificatives', type: :attachments, value: [attachment('Contrat.pdf'), attachment('Annexe.pdf')], previous_value: [attachment('Contrat.pdf'), attachment('Ancien.pdf')]),
      changed_column(label: 'Carte', type: :geojson, value: { type: 'FeatureCollection', features: [{}] }, previous_value: { type: 'FeatureCollection', features: [] }),
    ]

    render Dossiers::ChangesComponent.new(changed_columns:)
  end

  private

  def changed_column(label:, type:, value:, previous_value:)
    column = Column.new(procedure_id: 1, table: 'type_de_champ', column: 'preview', label:, type:)
    ChangedColumn.new(column, value, previous_value)
  end

  def attachment(filename)
    Struct.new(:blob).new(Struct.new(:filename).new(filename))
  end
end
