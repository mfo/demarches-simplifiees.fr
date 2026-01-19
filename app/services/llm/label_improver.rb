# frozen_string_literal: true

module LLM
  # Orchestrates improve_label generation using tool-calling.
  class LabelImprover < BaseImprover
    TOOL_DEFINITION = {
      type: 'function',
      function: {
        name: LLMRuleSuggestion.rules.fetch('improve_label'),
        description: "Améliore les libellés & descriptions en respectant les standards UX pour formulaires administratifs français. N'appelle cet outil QUE pour des améliorations significatives.",
        parameters: {
          type: 'object',
          properties: {
            update: {
              type: 'object',
              properties: {
                stable_id: { type: 'integer', description: 'Identifiant stable du champ à modifier' },
                libelle: { type: 'string', description: 'Nouveau libellé' },
                description: { type: 'string', description: 'Nouvelle description' },
              },
              required: %w[stable_id],
            },
            justification: { type: 'string', description: '1 phrase courte (< 10 mots) expliquant la raison de cette suggestion. Ne mentionne pas les regles ex: (règle 1.3)' },
          },
          required: %w[update justification],
        },
      },
    }.freeze

    def system_prompt(procedure = nil)
      ministries_value = procedure ? ministries(procedure) : nil
      service_value = procedure ? service(procedure) : nil
      target_audience_value = procedure ? target_audience(procedure) : nil

      prompt = <<-ROLE
        Tu es un expert en UX Writing pour les formulaires administratifs français.

        MÉTHODOLOGIE OBLIGATOIRE EN 2 PHASES :

        PHASE 1 OBLIGATOIRE - AUDIT (mental, pas de tool call) :
        Parcours TOUS les champs du schéma.
        Pour chaque champ, vérifie s'il viole une règle PRIORITÉ 1, 2 ou 3.
        Si OUI → Marque-le mentalement pour correction.

        PHASE 2 - CORRECTIONS (avec tool calls) :
        Pour CHAQUE champ marqué en Phase 1, génère UN tool call avec l'outil #{TOOL_DEFINITION.dig(:function, :name)}.
        Continue jusqu'à avoir traité TOUS les champs marqués.

        PÉRIMÈTRE D'ACTION :
        - Tu modifies : libelle, description
        - Tu ne touches JAMAIS à : stable_id, parent_id, position, type, mandatory, display_condition, sample_choices
      ROLE

      if [ministries_value, service_value, target_audience_value].any?(&:present?)
        context_lines = []
        context_lines << "- Porté par : #{ministries_value}" if ministries_value.present?
        context_lines << "- Instruit par : #{service_value}" if service_value.present?
        context_lines << "- S'adresse à : #{target_audience_value}" if target_audience_value.present?

        prompt += <<~CONTEXT

          CONTEXTE DU FORMULAIRE :
          #{context_lines.join("\n")}

          Le vocabulaire technique et spécialisé est légitime et doit être PRÉSERVÉ lorsqu'il correspond au champ lexical de ce ministère et de ce service.
        CONTEXT
      end

      prompt
    end

    def rules_prompt
      <<~TXT
        Applique ces règles PAR ORDRE DE PRIORITÉ.

        PRIORITÉ 1 : COHÉRENCE TECHNIQUE (bloquant si non respecté)

        1.1. Cohérence type/libellé/description
            • yes_no TOUJOURS une question (Avez-vous... ? Êtes-vous... ?)
              KO "Autre financeur public sollicité"
              OK "Avez-vous sollicité un autre financeur public ?"

            • drop_down_list TOUJOURS une question, a laquelle les choix répondent.
              OK "Vous êtes ?" + ["Une association", "Une entreprise"]
              KO "Type de structure" + ["Une association", "Une entreprise"]

            • Le libellé ne DOIT PAS être une répétition de la description et inversement.

            • Carte, commune, date, datetime, decimal_number, dossier_link, email, epci, iban, drop_down_list, linked_drop_down_list, multiple_drop_down_list, phone, rna, rnf, siret, titre_identite, piece_justificative
              Ne jamais ajouter de description si elle n'existe pas déjà, celle ci est ajoutée automatiquement par le système.


        1.2. Descriptions
            • Ne JAMAIS changer/supprimer une description si elle contient un lien ou un mail
            • Description = guide/exemple/format attendu UNIQUEMENT

        1.3. Display conditions
            • JAMAIS mentionner les conditions d'affichage dans le libellé
              KO "Adresse (hors France)" quand conditionné par pays != France
              OK "Adresse" (la condition gère déjà l'affichage)


        1.4. Acronymes et unités (PRÉSERVATION STRICTE)
            • JAMAIS remplacer un acronyme par un autre
              KO "ETPT" → "ETP" (ce sont deux concepts différents)
              KO "DROM" → "DOM-TOM" (terminologie obsolète)
            • JAMAIS modifier les unités de mesure
              OK "m²", "k€", "ETPT", "€ HT", "jours ouvrés"
            • Si un acronyme te semble peu clair : tu PEUX l'expliciter dans la description
              OK libellé "Nombre d'ETPT", description "ETPT = Équivalent Temps Plein Travaillé"

        PRIORITÉ 2 : PRÉSERVATION DU CONTEXTE (ne pas casser l'existant)

        2.1. Sections (header_section)
            • Éviter répétitions avec le titre de section
              Si section "Projet" alors champs suivant = "Description", pas "Description du projet"

            • Vérifier la cohérence et la lecture naturelle des champs suivants
              Si section "Je déclare" alors libellés = actions déclarées Ex: "que les informations sont exactes"

        2.2. Relations entre champs
            • PRÉSERVER les références croisées
              Si: "Nombre de salariés" suivi de "... dont en CDI"
              Alors garder la formulation "dont" qui référence le champ précédent
              KO "Nombre de salariés en CDI" (perd le lien)

            • PRÉSERVER les patterns répétés intentionnels
              Si "Recueil par X" + "Recueil par Y"
              Alors garder la structure similaire (choix de l'admin)
              KO "Recueil de données" (perd l'homogénéité)

        2.3. Jargon technique/légal/métier
            • Le vocabulaire technique et spécialisé est légitime et doit être PRÉSERVÉ lorsqu'il correspond au champ lexical du ministère porteur et du service instructeur.

            Exemples de légitimité contextuelle :
              Ministère de la Santé : termes médicaux, nomenclatures de soins, codes ALD
              Ministère de l'Éducation : cycles scolaires, VAE, ECTS, diplômes spécifiques
              Ministère de l'Agriculture : PAC, GAEC, exploitation agricole, parcelles cadastrales
              Ministère de la Culture : monuments historiques, DRAC, labels patrimoniaux
              Services techniques municipaux : voirie, assainissement, PLU, zonage

            Règle : Ne simplifie PAS un terme technique si :
            - Il est couramment utilisé par le public cible (professionnels du secteur)
            - Il correspond au domaine d'expertise du ministère/service
            - Sa simplification ferait perdre en précision juridique ou administrative

            Exemples concrets :
              OK : "Montant de la subvention PAC" (Ministère Agriculture, public = agriculteurs)
              OK : "Nombre d'ETPT demandés" (contexte RH, public = gestionnaires, subventions)
              KO : "Procédure d'adjudication" → "Procédure d'attribution" (perd la précision juridique pour un marché public)
              Si acronyme inconnu : le GARDER tel quel (c'est un choix métier de l'admin)

            • PRÉSERVER les termes métier essentiels
              OK "Indicateurs et méthodes d'évaluation" (pas juste "Indicateurs")
              OK "Montant en ETPT" (pas "Nombre de personnes" ou "ETP")


        PRIORITÉ 3 : SIMPLIFICATION (si 1 et 2 respectés)

        3.1. Longueur
            • Libellé idéalement ≤ 80 caractères
            • Description idéalement ≤ 160 caractères
            • Phrases < 12 mots (une idée/phrase)

        3.2. Langage
            • Mots simples, courants, concrets
            • Nombres en chiffres : "2 documents" pas "deux documents"
            • Forme active, syntaxe directe, Impératif bienveillant : "Envoyez" pas "Veuillez envoyer"
            • Éviter : veuillez, conformément à, parenthèses, doubles négations

        3.3. Informations pratiques (dans description)
            • Formats attendus
            • Dates limites
            • Contraintes spécifiques
            • Exemples concrets quand utile

        3.4. Accessibilité
            • "adresse électronique" (pas email/courriel)
            • JAMAIS indiquer "(optionnel)" ou "(si applicable)"
            • Sections JAMAIS préfixées par numéro
            • Pas de libélés en MAJUSCULES
      TXT
    end

    def build_item(args, tdc_index: {})
      update = args['update'].is_a?(Hash) ? args['update'] : {}
      stable_id = update['stable_id'] || args['stable_id']
      libelle = (update['libelle'] || args['libelle']).to_s.strip
      description = (update['description'] || args['description'])
      position = (update['position'] || args['position'])
      parent_id = (update['parent_id'] || args['parent_id'])

      return nil if filter_invalid_llm_result(stable_id, libelle, description)

      {
        op_kind: 'update',
        stable_id: stable_id,
        payload: { 'stable_id' => stable_id, 'libelle' => libelle, 'description' => description, 'position' => position, 'parent_id' => parent_id }.compact,
        justification: args['justification'].to_s.presence,
      }
    end

    def filter_invalid_llm_result(stable_id, libelle, description)
      return true if stable_id.blank?
      libelle.blank? && description.blank?
    end

    def target_audience(procedure)
      procedure.description_target_audience
    end

    def ministries(procedure)
      procedure.zones.map { it.labels.first }.join(", ")
    end

    def service(procedure)
      procedure.service&.pretty_nom
    end
  end
end
